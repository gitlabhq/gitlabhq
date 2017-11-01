module Gitlab
  module Git
    class Wiki
      DuplicatePageError = Class.new(StandardError)

      CommitDetails = Struct.new(:name, :email, :message) do
        def to_h
          { name: name, email: email, message: message }
        end
      end
      PageBlob = Struct.new(:name)

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
            gollum_wiki.clear_cache
          else
            gollum_write_page(name, format, content, commit_details)
          end
        end
      end

      def delete_page(page_path, commit_details)
        @repository.gitaly_migrate(:wiki_delete_page) do |is_enabled|
          if is_enabled
            gitaly_delete_page(page_path, commit_details)
            gollum_wiki.clear_cache
          else
            gollum_delete_page(page_path, commit_details)
          end
        end
      end

      def update_page(page_path, title, format, content, commit_details)
        assert_type!(format, Symbol)
        assert_type!(commit_details, CommitDetails)

        gollum_wiki.update_page(gollum_page_by_path(page_path), title, format, content, commit_details.to_h)
        nil
      end

      def pages
        gollum_wiki.pages.map { |gollum_page| new_page(gollum_page) }
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

      def page_versions(page_path)
        current_page = gollum_page_by_path(page_path)
        current_page.versions.map do |gollum_git_commit|
          gollum_page = gollum_wiki.page(current_page.title, gollum_git_commit.id)
          new_version(gollum_page, gollum_git_commit.id)
        end
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

      private

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
        commit = Gitlab::Git::Commit.find(@repository, commit_id)
        Gitlab::Git::WikiPageVersion.new(commit, gollum_page&.format)
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

        gollum_wiki.write_page(name, format, content, commit_details.to_h)

        nil
      rescue Gollum::DuplicatePageError => e
        raise Gitlab::Git::Wiki::DuplicatePageError, e.message
      end

      def gollum_delete_page(page_path, commit_details)
        assert_type!(commit_details, CommitDetails)

        gollum_wiki.delete_page(gollum_page_by_path(page_path), commit_details.to_h)
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

      def gitaly_write_page(name, format, content, commit_details)
        gitaly_wiki_client.write_page(name, format, content, commit_details)
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
    end
  end
end
