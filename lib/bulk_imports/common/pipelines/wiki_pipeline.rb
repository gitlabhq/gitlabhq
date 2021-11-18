# frozen_string_literal: true

module BulkImports
  module Common
    module Pipelines
      class WikiPipeline
        include Pipeline

        def extract(*)
          BulkImports::Pipeline::ExtractedData.new(data: { url: url_from_parent_path(context.entity.source_full_path) })
        end

        def transform(_, data)
          data&.slice(:url)
        end

        def load(context, data)
          return unless context.portable.wiki

          url = data[:url].sub("://", "://oauth2:#{context.configuration.access_token}@")

          Gitlab::UrlBlocker.validate!(url, allow_local_network: allow_local_requests?, allow_localhost: allow_local_requests?)

          context.portable.wiki.ensure_repository
          context.portable.wiki.repository.fetch_as_mirror(url)
        end

        private

        def url_from_parent_path(parent_path)
          wiki_path = parent_path + ".wiki.git"
          root = context.configuration.url
          Gitlab::Utils.append_path(root, wiki_path)
        end

        def allow_local_requests?
          Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
        end
      end
    end
  end
end
