# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class SnippetsRepositoryPipeline
        include Pipeline
        include HexdigestCacheStrategy

        extractor Common::Extractors::GraphqlExtractor, query: Graphql::GetSnippetRepositoryQuery

        def transform(_context, data)
          data.tap do |d|
            d['createdAt'] = DateTime.parse(data['createdAt'])
          end
        end

        def load(context, data)
          return unless data['httpUrlToRepo'].present?

          oauth2_url = oauth2(data['httpUrlToRepo'])

          matched_snippet = find_matched_snippet(data)
          # Skip snippets that we couldn't find a match. Probably because more snippets were
          # added after the migration had already started, namely after the SnippetsPipeline
          # has already run.
          return unless matched_snippet

          resolved_address = validate_url(oauth2_url)

          matched_snippet.create_repository
          matched_snippet.repository.fetch_as_mirror(oauth2_url, resolved_address: resolved_address)
          response = Snippets::RepositoryValidationService.new(nil, matched_snippet).execute

          # skips matched_snippet repository creation if repository is invalid
          return cleanup_snippet_repository(matched_snippet) if response.error?

          Snippets::UpdateStatisticsService.new(matched_snippet).execute
        end

        private

        def find_matched_snippet(data)
          Snippet.find_by_project_title_trunc_created_at(
            context.portable, data['title'], data['createdAt'])
        end

        def allow_local_requests?
          Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
        end

        def oauth2(url)
          url.sub("://", "://oauth2:#{context.configuration.access_token}@")
        end

        def validate_url(url)
          validated_url, resolved_host = Gitlab::HTTP_V2::UrlBlocker.validate!(
            url,
            allow_local_network: allow_local_requests?,
            allow_localhost: allow_local_requests?,
            dns_rebind_protection: dns_rebind_protection?,
            deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
            schemes: %w[http https],
            outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist # rubocop:disable Naming/InclusiveLanguage -- existing setting
          )

          return '' if resolved_host.blank? || !validated_url.scheme.in?(%w[http https])

          validated_url.hostname.to_s
        end

        def dns_rebind_protection?
          return false if Gitlab.http_proxy_env?

          Gitlab::CurrentSettings.dns_rebinding_protection_enabled?
        end

        def cleanup_snippet_repository(snippet)
          snippet.repository.remove
          snippet.snippet_repository.delete
          snippet.repository.expire_exists_cache
        end
      end
    end
  end
end
