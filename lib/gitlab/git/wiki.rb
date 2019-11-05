# frozen_string_literal: true

module Gitlab
  module Git
    class Wiki
      include Gitlab::Git::WrapsGitalyErrors

      DuplicatePageError = Class.new(StandardError)
      OperationError = Class.new(StandardError)

      DEFAULT_PAGINATION = Kaminari.config.default_per_page

      CommitDetails = Struct.new(:user_id, :username, :name, :email, :message) do
        def to_h
          { user_id: user_id, username: username, name: name, email: email, message: message }
        end
      end

      # GollumSlug inlines just enough knowledge from Gollum::Page to generate a
      # slug, which is used when previewing pages that haven't been persisted
      class GollumSlug
        class << self
          def cname(name, char_white_sub = '-', char_other_sub = '-')
            if name.respond_to?(:gsub)
              name.gsub(/\s/, char_white_sub).gsub(/[<>+]/, char_other_sub)
            else
              ''
            end
          end

          def format_to_ext(format)
            format == :markdown ? "md" : format.to_s
          end

          def canonicalize_filename(filename)
            ::File.basename(filename, ::File.extname(filename)).tr('-', ' ')
          end

          def generate(title, format)
            ext = format_to_ext(format.to_sym)
            name = cname(title) + '.' + ext
            canonical_name = canonicalize_filename(name)

            path =
              if name.include?('/')
                name.sub(%r{/[^/]+$}, '/')
              else
                ''
              end

            path + cname(canonical_name, '-', '-')
          end
        end
      end

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
        wrapped_gitaly_errors do
          gitaly_write_page(name, format, content, commit_details)
        end
      end

      def delete_page(page_path, commit_details)
        wrapped_gitaly_errors do
          gitaly_delete_page(page_path, commit_details)
        end
      end

      def update_page(page_path, title, format, content, commit_details)
        wrapped_gitaly_errors do
          gitaly_update_page(page_path, title, format, content, commit_details)
        end
      end

      def list_pages(limit: 0, sort: nil, direction_desc: false, load_content: false)
        wrapped_gitaly_errors do
          gitaly_list_pages(
            limit: limit,
            sort: sort,
            direction_desc: direction_desc,
            load_content: load_content
          )
        end
      end

      def page(title:, version: nil, dir: nil)
        wrapped_gitaly_errors do
          gitaly_find_page(title: title, version: version, dir: dir)
        end
      end

      def file(name, version)
        wrapped_gitaly_errors do
          gitaly_find_file(name, version)
        end
      end

      # options:
      #  :page     - The Integer page number.
      #  :per_page - The number of items per page.
      #  :limit    - Total number of items to return.
      def page_versions(page_path, options = {})
        versions = wrapped_gitaly_errors do
          gitaly_wiki_client.page_versions(page_path, options)
        end

        # Gitaly uses gollum-lib to get the versions. Gollum defaults to 20
        # per page, but also fetches 20 if `limit` or `per_page` < 20.
        # Slicing returns an array with the expected number of items.
        slice_bound = options[:limit] || options[:per_page] || DEFAULT_PAGINATION
        versions[0..slice_bound]
      end

      def count_page_versions(page_path)
        @repository.count_commits(ref: 'HEAD', path: page_path)
      end

      def preview_slug(title, format)
        GollumSlug.generate(title, format)
      end

      private

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

      def gitaly_list_pages(limit: 0, sort: nil, direction_desc: false, load_content: false)
        params = { limit: limit, sort: sort, direction_desc: direction_desc }

        gitaly_pages =
          if load_content
            gitaly_wiki_client.load_all_pages(params)
          else
            gitaly_wiki_client.list_all_pages(params)
          end

        gitaly_pages.map do |wiki_page, version|
          Gitlab::Git::WikiPage.new(wiki_page, version)
        end
      end
    end
  end
end
