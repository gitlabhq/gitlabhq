# Gitlab::Git::Gitlab::Git::Commit is a wrapper around native Grit::Repository object
# We dont want to use grit objects inside app/
# It helps us easily migrate to rugged in future
module Gitlab
  module Git
    class Repository
      include Gitlab::Popen

      class NoRepository < StandardError; end

      # Repository directory name with namespace direcotry
      # Examples:
      #   gitlab/gitolite
      #   diaspora
      #
      attr_accessor :path_with_namespace

      # Grit repo object
      attr_accessor :repo

      # Default branch in the repository
      attr_accessor :root_ref

      def initialize(path_with_namespace, root_ref = 'master')
        @root_ref = root_ref || "master"
        @path_with_namespace = path_with_namespace

        # Init grit repo object
        repo
      end

      def raw
        repo
      end

      def path_to_repo
        @path_to_repo ||= File.join(repos_path, "#{path_with_namespace}.git")
      end

      def repos_path
        Gitlab.config.gitlab_shell.repos_path
      end

      def repo
        @repo ||= Grit::Repo.new(path_to_repo)
      rescue Grit::NoSuchPathError
        raise NoRepository.new('no repository for such path')
      end

      def commit(commit_id = nil)
        commit = if commit_id
                   # Find repo.refs first,
                   # because if commit_id is "tag name",
                   # repo.commit(commit_id) returns wrong commit sha
                   # that is git tag object sha.
                   ref = repo.refs.find {|r| r.name == commit_id}
                   if ref
                     ref.commit
                   else
                     repo.commit(commit_id)
                   end
                 else
                   repo.commits(root_ref).first
                 end

        decorate_commit(commit) if commit
      end

      def commits_with_refs(n = 20)
        commits = repo.branches.map { |ref| decorate_commit(ref.commit, ref) }

        commits.sort! do |x, y|
          y.committed_date <=> x.committed_date
        end

        commits[0..n]
      end

      def commits(ref, path = nil, limit = nil, offset = nil)
        if path.present?
          repo.log(ref, path, max_count: limit, skip: offset, follow: true)
        elsif limit && offset
          repo.commits(ref, limit.to_i, offset.to_i)
        else
          repo.commits(ref)
        end.map{ |c| decorate_commit(c) }
      end

      def commits_between(from, to)
        repo.commits_between(from, to).map { |c| decorate_commit(c) }
      end

      def last_commit_for(ref, path = nil)
        commits(ref, path, 1).first
      end

      # Returns an Array of branch names
      # sorted by name ASC
      def branch_names
        branches.map(&:name)
      end

      # Returns an Array of Branches
      def branches
        repo.branches.sort_by(&:name)
      end

      # Returns an Array of tag names
      def tag_names
        repo.tags.collect(&:name).sort.reverse
      end

      # Returns an Array of Tags
      def tags
        repo.tags.sort_by(&:name).reverse
      end

      # Returns an Array of branch and tag names
      def ref_names
        [branch_names + tag_names].flatten
      end

      def heads
        @heads ||= repo.heads
      end

      def tree(fcommit, path = nil)
        fcommit = commit if fcommit == :head
        tree = fcommit.tree
        path ? (tree / path) : tree
      end

      def has_commits?
        !!commit
      rescue Grit::NoSuchPathError
        false
      end

      def empty?
        !has_commits?
      end

      # Discovers the default branch based on the repository's available branches
      #
      # - If no branches are present, returns nil
      # - If one branch is present, returns its name
      # - If two or more branches are present, returns the one that has a name
      #   matching root_ref (default_branch or 'master' if default_branch is nil)
      def discover_default_branch
        if branch_names.length == 0
          nil
        elsif branch_names.length == 1
          branch_names.first
        else
          branch_names.select { |v| v == root_ref }.first
        end
      end

      # Archive Project to .tar.gz
      #
      # Already packed repo archives stored at
      # app_root/tmp/repositories/project_name/project_name-commit-id.tag.gz
      #
      def archive_repo(ref)
        ref = ref || self.root_ref
        commit = self.commit(ref)
        return nil unless commit

        # Build file path
        file_name = self.path_with_namespace.gsub("/","_") + "-" + commit.id.to_s + ".tar.gz"
        storage_path = Rails.root.join("tmp", "repositories")
        file_path = File.join(storage_path, self.path_with_namespace, file_name)

        # Put files into a directory before archiving
        prefix = File.basename(self.path_with_namespace) + "/"

        # Create file if not exists
        unless File.exists?(file_path)
          FileUtils.mkdir_p File.dirname(file_path)
          file = self.repo.archive_to_file(ref, prefix,  file_path)
        end

        file_path
      end

      # Return repo size in megabytes
      # Cached in redis
      def size
        Rails.cache.fetch(cache_key(:size)) do
          size = popen('du -s', path_to_repo).first.strip.to_i
          (size.to_f / 1024).round(2)
        end
      end

      def expire_cache
        Rails.cache.delete(cache_key(:size))
      end

      def cache_key(type)
        "#{type}:#{path_with_namespace}"
      end

      def diffs_between(source_branch, target_branch)
        # Only show what is new in the source branch compared to the target branch, not the other way around.
        # The linex below with merge_base is equivalent to diff with three dots (git diff branch1...branch2)
        # From the git documentation: "git diff A...B" is equivalent to "git diff $(git-merge-base A B) B"
        common_commit = repo.git.native(:merge_base, {}, [target_branch, source_branch]).strip
        repo.diff(common_commit, source_branch).map { |diff| Gitlab::Git::Diff.new(diff) }

      rescue Grit::Git::GitTimeout
        [Gitlab::Git::Diff::BROKEN_DIFF]
      end

      protected

      def decorate_commit(commit, ref = nil)
        Gitlab::Git::Commit.new(commit, ref)
      end
    end
  end
end
