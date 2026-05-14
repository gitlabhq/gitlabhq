# frozen_string_literal: true

module WikiPages
  class EventCreateService
    # @param [User] author The event author
    def initialize(author)
      raise ArgumentError, 'author must not be nil' unless author

      @author = author
    end

    def execute(slug, page, action, event_fingerprint)
      wiki_page_meta = WikiPage::Meta.find_or_create(slug, page)

      event = ::EventCreateService.new.wiki_event(wiki_page_meta, author, action, event_fingerprint)

      ServiceResponse.success(payload: { event: event })
    rescue ::EventCreateService::IllegalActionError, ::ActiveRecord::ActiveRecordError => e
      ServiceResponse.error(message: e.message, payload: { error: e })
    end

    private

    attr_reader :author
  end
end
