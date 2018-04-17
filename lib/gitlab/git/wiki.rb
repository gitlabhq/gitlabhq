module Gitlab
  module Git
    class Wiki
      DuplicatePageError = Class.new(StandardError)
      OperationError = Class.new(StandardError)

      CommitDetails = Struct.new(:name, :email, :message) do
        def to_h
          { name: name, email: email, message: message }
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
        @repository.gitaly_migrate(:wiki_write_page) do |is_enabled|
          if is_enabled
            gitaly_write_page(name, format, content, commit_details)
          else
            gollum_write_page(name, format, content, commit_details)
          end
        end
      end

      def delete_page(page_path, commit_details)
        @repository.gitaly_migrate(:wiki_delete_page) do |is_enabled|
          if is_enabled
            gitaly_delete_page(page_path, commit_details)
          else
            gollum_delete_page(page_path, commit_details)
          end
        end
      end

      def update_page(page_path, title, format, content, commit_details)
        @repository.gitaly_migrate(:wiki_update_page) do |is_enabled|
          if is_enabled
            gitaly_update_page(page_path, title, format, content, commit_details)
          else
            gollum_update_page(page_path, title, format, content, commit_details)
          end
        end
      end

      def pages(limit: nil)
        @repository.gitaly_migrate(:wiki_get_all_pages) do |is_enabled|
          if is_enabled
            gitaly_get_all_pages
          else
            gollum_get_all_pages(limit: limit)
          end
        end
      end

      def page(title:, version: nil, dir: nil)
        @repository.gitaly_migrate(:wiki_find_page) do |is_enabled|
          if is_enabled
            gitaly_find_page(title: title, version: version, dir: dir)
          else
            gollum_find_page(title: title, version: version, dir: dir)
          end
        end
      end

      def file(name, version)
        @repository.gitaly_migrate(:wiki_find_file) do |is_enabled|
          if is_enabled
            gitaly_find_file(name, version)
          else
            gollum_find_file(name, version)
          end
        end
      end

      # options:
      #  :page     - The Integer page number.
      #  :per_page - The number of items per page.
      #  :limit    - Total number of items to return.
      def page_versions(page_path, options = {})
        @repository.gitaly_migrate(:wiki_page_versions) do |is_enabled|
          if is_enabled
            versions = gitaly_wiki_client.page_versions(page_path, options)

            # Gitaly uses gollum-lib to get the versions. Gollum defaults to 20
            # per page, but also fetches 20 if `limit` or `per_page` < 20.
            # Slicing returns an array with the expected number of items.
            slice_bound = options[:limit] || options[:per_page] || Gollum::Page.per_page
            versions[0..slice_bound]
          else
            current_page = gollum_page_by_path(page_path)

            commits_from_page(current_page, options).map do |gitlab_git_commit|
              gollum_page = gollum_wiki.page(current_page.title, gitlab_git_commit.id)
              Gitlab::Git::WikiPageVersion.new(gitlab_git_commit, gollum_page&.format)
            end
          end
        end
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

        @repository.gitaly_migrate(:wiki_page_formatted_data) do |is_enabled|
          if is_enabled
            gitaly_wiki_client.get_formatted_data(title: title, dir: dir, version: version)
          else
            # We don't use #page because if wiki_find_page feature is enabled, we would
            # get a page without formatted_data.
            gollum_find_page(title: title, dir: dir, version: version)&.formatted_data
          end
        end
      end

      private

      # options:
      #  :page     - The Integer page number.
      #  :per_page - The number of items per page.
      #  :limit    - Total number of items to return.
      def commits_from_page(gollum_page, options = {})
        unless options[:limit]
          options[:offset] = ([1, options.delete(:page).to_i].max - 1) * Gollum::Page.per_page
          options[:limit] = (options.delete(:per_page) || Gollum::Page.per_page).to_i
        end

        @repository.log(ref: gollum_page.last_version.id,
                        path: gollum_page.path,
                        limit: options[:limit],
                        offset: options[:offset])
      end

      def gollum_wiki
        @gollum_wiki ||= Gollum::Wiki.new(@repository.path)
      end

      def gollum_page_by_path(page_path)
        page_name = Gollum::Page.canonicalize_filename(page_path)
        page_dir = File.split(page_path).first

        gollum_wiki.paged(page_name, page_dir)
      end

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

      def gollum_write_page(name, format, content, commit_details)
        assert_type!(format, Symbol)
        assert_type!(commit_details, CommitDetails)

        filename = File.basename(name)
        dir = (tmp_dir = File.dirname(name)) == '.' ? '' : tmp_dir

        gollum_wiki.write_page(filename, format, content, commit_details.to_h, dir)

        nil
      rescue Gollum::DuplicatePageError => e
        raise Gitlab::Git::Wiki::DuplicatePageError, e.message
      end

      def gollum_delete_page(page_path, commit_details)
        assert_type!(commit_details, CommitDetails)

        gollum_wiki.delete_page(gollum_page_by_path(page_path), commit_details.to_h)

        nil
      end

      def gollum_update_page(page_path, title, format, content, commit_details)
        assert_type!(format, Symbol)
        assert_type!(commit_details, CommitDetails)

        page = gollum_page_by_path(page_path)
        committer = Gollum::Committer.new(page.wiki, commit_details.to_h)

        # Instead of performing two renames if the title has changed,
        # the update_page will only update the format and content and
        # the rename_page will do anything related to moving/renaming
        gollum_wiki.update_page(page, page.name, format, content, committer: committer)
        gollum_wiki.rename_page(page, title, committer: committer)
        committer.commit
        nil
      end

      def gollum_find_page(title:, version: nil, dir: nil)
        if version
          version = Gitlab::Git::Commit.find(@repository, version).id
        end

        gollum_page = gollum_wiki.page(title, version, dir)
        return unless gollum_page

        new_page(gollum_page)
      end

      def gollum_find_file(name, version)
        version ||= self.class.default_ref
        gollum_file = gollum_wiki.file(name, version)
        return unless gollum_file

        Gitlab::Git::WikiFile.new(gollum_file)
      end

      def gollum_get_all_pages(limit: nil)
        gollum_wiki.pages(limit: limit).map { |gollum_page| new_page(gollum_page) }
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

      def gitaly_get_all_pages
        gitaly_wiki_client.get_all_pages.map do |wiki_page, version|
          Gitlab::Git::WikiPage.new(wiki_page, version)
        end
      end
    end
  end
end
