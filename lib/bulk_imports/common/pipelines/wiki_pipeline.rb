# frozen_string_literal: true

module BulkImports
  module Common
    module Pipelines
      class WikiPipeline
        include Pipeline

        def extract(*)
          url = url_from_parent_path(context.entity.source_full_path) if source_wiki_exists?

          BulkImports::Pipeline::ExtractedData.new(data: { url: url })
        end

        def transform(_, data)
          data&.slice(:url)
        end

        def load(context, data)
          return unless data&.dig(:url)

          wiki = context.portable.wiki
          url = data[:url].sub("://", "://oauth2:#{context.configuration.access_token}@")

          resolved_address = get_resolved_address(url)

          wiki.create_wiki_repository
          wiki.repository.fetch_as_mirror(url, resolved_address: resolved_address)
        end

        private

        def url_from_parent_path(parent_path)
          wiki_path = parent_path + ".wiki.git"
          root = context.configuration.url
          Gitlab::Utils.append_path(root, wiki_path)
        end

        def get_resolved_address(url)
          validated_url, resolved_host = Gitlab::HTTP_V2::UrlBlocker.validate!(
            url,
            schemes: %w[http https],
            allow_local_network: allow_local_requests?,
            allow_localhost: allow_local_requests?,
            dns_rebind_protection: dns_rebind_protection?,
            deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
            outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist # rubocop:disable Naming/InclusiveLanguage -- existing setting
          )

          return '' if resolved_host.blank? || !validated_url.scheme.in?(%w[http https])

          validated_url.hostname.to_s
        end

        def allow_local_requests?
          Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
        end

        def dns_rebind_protection?
          return false if Gitlab.http_proxy_env?

          Gitlab::CurrentSettings.dns_rebinding_protection_enabled?
        end

        def source_wiki_exists?
          wikis = client.get(context.entity.wikis_url_path).parsed_response

          wikis.any?
        rescue BulkImports::NetworkError => e
          # 403 is returned when wiki is disabled in settings
          return if e.response&.forbidden? || e.response&.not_found?

          raise
        end

        def client
          BulkImports::Clients::HTTP.new(url: context.configuration.url, token: context.configuration.access_token)
        end
      end
    end
  end
end
