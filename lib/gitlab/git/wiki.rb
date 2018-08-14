module Gitlab
  module Git
    class Wiki
      DuplicatePageError = Class.new(StandardError)
      OperationError = Class.new(StandardError)

      CommitDetails = Struct.new(:user_id, :username, :name, :email, :message) do
        def to_h
          { user_id: user_id, username: username, name: name, email: email, message: message }
        end
      end
      PageBlob = Struct.new(:name)

      attr_reader :repository

      def self.default_ref
        'master'
      end

      # Initialize with a Gitlab::Git::Repository instance
      def initialize(repository)
        @repository = repository
      end

      def repository_exists?
        @repository.exists?
      end

      def write_page(name, format, content, commit_details)
        @repository.wrapped_gitaly_errors do
          gitaly_write_page(name, format, content, commit_details)
        end
      end

      def delete_page(page_path, commit_details)
        @repository.wrapped_gitaly_errors do
          gitaly_delete_page(page_path, commit_details)
        end
      end

      def update_page(page_path, title, format, content, commit_details)
        @repository.wrapped_gitaly_errors do
          gitaly_update_page(page_path, title, format, content, commit_details)
        end
      end

      def pages(limit: 0)
        @repository.wrapped_gitaly_errors do
          gitaly_get_all_pages(limit: limit)
        end
      end

      def page(title:, version: nil, dir: nil)
        @repository.wrapped_gitaly_errors do
          gitaly_find_page(title: title, version: version, dir: dir)
        end
      end

      def file(name, version)
        @repository.wrapped_gitaly_errors do
          gitaly_find_file(name, version)
        end
      end

      # options:
      #  :page     - The Integer page number.
      #  :per_page - The number of items per page.
      #  :limit    - Total number of items to return.
      def page_versions(page_path, options = {})
        versions = @repository.wrapped_gitaly_errors do
          gitaly_wiki_client.page_versions(page_path, options)
        end

        # Gitaly uses gollum-lib to get the versions. Gollum defaults to 20
        # per page, but also fetches 20 if `limit` or `per_page` < 20.
        # Slicing returns an array with the expected number of items.
        slice_bound = options[:limit] || options[:per_page] || Gollum::Page.per_page
        versions[0..slice_bound]
      end

      def count_page_versions(page_path)
        @repository.count_commits(ref: 'HEAD', path: page_path)
      end

      def preview_slug(title, format)
        # Adapted from gollum gem (Gollum::Wiki#preview_page) to avoid
        # using Rugged through a Gollum::Wiki instance
        page_class = Gollum::Page
        page = page_class.new(nil)
        ext = page_class.format_to_ext(format.to_sym)
        name = page_class.cname(title) + '.' + ext
        blob = PageBlob.new(name)
        page.populate(blob)
        page.url_path
      end

      def page_formatted_data(title:, dir: nil, version: nil)
        version = version&.id

        @repository.wrapped_gitaly_errors do
          gitaly_wiki_client.get_formatted_data(title: title, dir: dir, version: version)
        end
      end

      private

      def new_page(gollum_page)
        Gitlab::Git::WikiPage.new(gollum_page, new_version(gollum_page, gollum_page.version.id))
      end

      def new_version(gollum_page, commit_id)
        Gitlab::Git::WikiPageVersion.new(version(commit_id), gollum_page&.format)
      end

      def version(commit_id)
        commit_find_proc = -> { Gitlab::Git::Commit.find(@repository, commit_id) }

        if RequestStore.active?
          RequestStore.fetch([:wiki_version_commit, commit_id]) { commit_find_proc.call }
        else
          commit_find_proc.call
        end
      end

      def assert_type!(object, klass)
        unless object.is_a?(klass)
          raise ArgumentError, "expected a #{klass}, got #{object.inspect}"
        end
      end

      def gitaly_wiki_client
        @gitaly_wiki_client ||= Gitlab::GitalyClient::WikiService.new(@repository)
      end

      def gitaly_write_page(name, format, content, commit_details)
        gitaly_wiki_client.write_page(name, format, content, commit_details)
      end

      def gitaly_update_page(page_path, title, format, content, commit_details)
        gitaly_wiki_client.update_page(page_path, title, format, content, commit_details)
      end

      def gitaly_delete_page(page_path, commit_details)
        gitaly_wiki_client.delete_page(page_path, commit_details)
      end

      def gitaly_find_page(title:, version: nil, dir: nil)
        wiki_page, version = gitaly_wiki_client.find_page(title: title, version: version, dir: dir)
        return unless wiki_page

        Gitlab::Git::WikiPage.new(wiki_page, version)
      end

      def gitaly_find_file(name, version)
        wiki_file = gitaly_wiki_client.find_file(name, version)
        return unless wiki_file

        Gitlab::Git::WikiFile.new(wiki_file)
      end

      def gitaly_get_all_pages(limit: 0)
        gitaly_wiki_client.get_all_pages(limit: limit).map do |wiki_page, version|
          Gitlab::Git::WikiPage.new(wiki_page, version)
        end
      end

      def committer_with_hooks(commit_details)
        Gitlab::Git::CommitterWithHooks.new(self, commit_details.to_h)
      end

      def with_committer_with_hooks(commit_details, &block)
        committer = committer_with_hooks(commit_details)

        yield committer

        committer.commit

        nil
      end
    end
  end
end
