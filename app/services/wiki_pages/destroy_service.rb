# frozen_string_literal: true

module WikiPages
  class DestroyService < WikiPages::BaseService
    def execute(page)
      if page.delete
        execute_hooks(page)
        mark_meta_as_deleted(page)
        ServiceResponse.success(payload: { page: page })
      else
        message = page.template? ? _('Could not delete wiki template') : _('Could not delete wiki page')
        ServiceResponse.error(message: message, payload: { page: page })
      end
    end

    def internal_event_name
      'delete_wiki_page'
    end

    def external_action
      'delete'
    end

    def event_action
      :destroyed
    end

    def fingerprint(page)
      page.wiki.repository.head_commit.sha
    end

    def mark_meta_as_deleted(page)
      meta = page.find_or_create_meta
      meta.update!(deleted_at: Time.current)
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e,
        wiki_page_title: page.title,
        wiki_page_slug: page.slug
      )
    end
  end
end

WikiPages::DestroyService.prepend_mod_with('WikiPages::DestroyService')
