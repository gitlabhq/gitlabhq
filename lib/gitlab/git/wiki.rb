# frozen_string_literal: true

module Gitlab
  module Git
    class Wiki
      include Gitlab::Git::WrapsGitalyErrors

      DuplicatePageError = Class.new(StandardError)

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

      # TODO remove argument when issue
      # https://gitlab.com/gitlab-org/gitlab/-/issues/329190
      # is closed.
      def self.default_ref(container = nil)
        Gitlab::DefaultBranch.value(object: container)
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

      def gitaly_find_page(title:, version: nil, dir: nil)
        return unless title.present?

        wiki_page, version = gitaly_wiki_client.find_page(title: title, version: version, dir: dir)
        return unless wiki_page

        Gitlab::Git::WikiPage.new(wiki_page, version)
      rescue GRPC::InvalidArgument
        nil
      end

      def gitaly_list_pages(limit: 0, sort: nil, direction_desc: false, load_content: false)
        params = { limit: limit, sort: sort, direction_desc: direction_desc }

        gitaly_pages =
          if load_content
            gitaly_wiki_client.load_all_pages(**params)
          else
            gitaly_wiki_client.list_all_pages(**params)
          end

        gitaly_pages.map do |wiki_page, version|
          Gitlab::Git::WikiPage.new(wiki_page, version)
        end
      end
    end
  end
end
