# frozen_string_literal: true

module Repositories
  class CacheTagSignaturesWorker
    include ApplicationWorker

    urgency :low
    defer_on_database_health_signal :gitlab_main, [:tag_ssh_signatures, :tag_gpg_signatures], 1.minute
    data_consistency :sticky
    deduplicate :until_executed
    idempotent!
    feature_category :source_code_management
    sidekiq_options retry: false

    READ_TIMEOUT = Gitlab::GitalyClient.medium_timeout
    ALLOWED_CLASS_STRINGS_TO_CLASS = {
      'Gitlab::Gpg::Tag': Gitlab::Gpg::Tag,
      'Gitlab::Ssh::Tag': Gitlab::Ssh::Tag
    }.freeze

    def perform(project_id, params = {})
      project = Project.find_by_id(project_id)
      return unless project

      params.deep_symbolize_keys!

      signed_tag_contexts = params[:class_to_context]
      signed_tags = signed_tag_contexts.flat_map do |klass, contexts|
        klass_constant = ALLOWED_CLASS_STRINGS_TO_CLASS[klass]
        next unless klass_constant

        contexts.map do |context|
          klass_constant.new(project.repository, context)
        end
      end

      # Batch load the signatures
      cached_signatures = signed_tags.compact.map do |st|
        st.lazy_cached_signature(timeout: READ_TIMEOUT)
      end

      cached_signatures.each do |sig|
        next if sig.nil?

        sig.verification_status
      end
    end
  end
end
