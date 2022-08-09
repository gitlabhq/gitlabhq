# frozen_string_literal: true

module Pages
  class InvalidateDomainCacheWorker
    include Gitlab::EventStore::Subscriber

    idempotent!

    feature_category :pages

    def handle_event(event)
      if event.data[:project_id]
        ::Gitlab::Pages::CacheControl
          .for_project(event.data[:project_id])
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
  end
end
