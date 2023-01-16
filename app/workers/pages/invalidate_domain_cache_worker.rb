# frozen_string_literal: true

module Pages
  class InvalidateDomainCacheWorker
    include Gitlab::EventStore::Subscriber

    idempotent!

    feature_category :pages

    def handle_event(event)
      domain_ids(event).each do |domain_id|
        ::Gitlab::Pages::CacheControl
          .for_domain(domain_id)
          .clear_cache
      end

      event.data.values_at(
        :root_namespace_id,
        :old_root_namespace_id,
        :new_root_namespace_id
      ).compact.uniq.each do |namespace_id|
        ::Gitlab::Pages::CacheControl
          .for_namespace(namespace_id)
          .clear_cache
      end
    end

    def domain_ids(event)
      ids = PagesDomain.ids_for_project(event.data[:project_id])

      ids << event.data[:domain_id] if event.data[:domain_id]

      ids
    end
  end
end
