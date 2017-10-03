module Gitlab
  module Git
    class Wiki
      DuplicatePageError = Class.new(StandardError)

      CommitDetails = Struct.new(:name, :email, :message) do
        def to_h
          { name: name, email: email, message: message }
        end
      end

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
        assert_type!(format, Symbol)
        assert_type!(commit_details, CommitDetails)

        gollum_wiki.write_page(name, format, content, commit_details.to_h)

        nil
      rescue Gollum::DuplicatePageError => e
        raise Gitlab::Git::Wiki::DuplicatePageError, e.message
      end

      def delete_page(page_path, commit_details)
        assert_type!(commit_details, CommitDetails)

        gollum_wiki.delete_page(gollum_page_by_path(page_path), commit_details.to_h)
        nil
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
        if version
          version = Gitlab::Git::Commit.find(@repository, version).id
        end

        gollum_page = gollum_wiki.page(title, version, dir)
        return unless gollum_page

        new_page(gollum_page)
      end

      def file(name, version)
        version ||= self.class.default_ref
        gollum_file = gollum_wiki.file(name, version)
        return unless gollum_file

        Gitlab::Git::WikiFile.new(gollum_file)
      end

      def page_versions(page_path)
        current_page = gollum_page_by_path(page_path)
        current_page.versions.map do |gollum_git_commit|
          gollum_page = gollum_wiki.page(current_page.title, gollum_git_commit.id)
          new_version(gollum_page, gollum_git_commit.id)
        end
      end

      def preview_slug(title, format)
        gollum_wiki.preview_page(title, '', format).url_path
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
    end
  end
end
