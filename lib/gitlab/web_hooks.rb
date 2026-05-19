# frozen_string_literal: true

module Gitlab
  module WebHooks
    GITLAB_EVENT_HEADER = 'X-Gitlab-Event'
    GITLAB_INSTANCE_HEADER = 'X-Gitlab-Instance'
    GITLAB_UUID_HEADER = 'X-Gitlab-Webhook-UUID'
    WEBHOOK_ID_HEADER = 'webhook-id'
    WEBHOOK_SIGNATURE_HEADER = 'webhook-signature'
    WEBHOOK_TIMESTAMP_HEADER = 'webhook-timestamp'

    class << self
      def prepare_data(data)
        data = data.with_indifferent_access

        return data unless data[:object_kind] == 'wiki_page'

        prepare_wiki_data(data)
      end

      # Recursively replaces Time/Date-like values in a webhook payload with
      # ISO 8601 strings. Called on both webhook delivery paths: the async path
      # (before enqueuing to Sidekiq) and the sync path (before rendering a
      # custom template), so the renderer sees the same string format in both.
      def normalize_dates(value)
        case value
        when Time, DateTime, ActiveSupport::TimeWithZone
          value.iso8601(3)
        when Date
          value.iso8601
        when Hash
          value.transform_values { |v| normalize_dates(v) }
        when Array
          value.map { |v| normalize_dates(v) }
        else
          value
        end
      end

      private

      # Wiki webhook data does not have "content" attribute yet.
      # As Wiki content is versioned in git, we can lazily retrieve the content
      # from source control and it will be identical to when webhook event was triggered.
      # This is an optimization to serializing wiki content data which can
      # sometimes be over the Sidekiq payload limit.
      def prepare_wiki_data(data)
        project_id = data.dig(:project, :id)
        slug = data.dig(:object_attributes, :slug)
        version_id = data.dig(:object_attributes, :version_id)
        return data unless [project_id, slug, version_id].all?(&:present?)

        wiki = ProjectWiki.find_by_id(project_id)
        return data unless wiki

        page = wiki.find_page(slug, version_id)
        return data unless page

        data.deep_merge(object_attributes: { content: Gitlab::HookData::WikiPageBuilder.new(page).page_content })
      end
    end
  end
end
