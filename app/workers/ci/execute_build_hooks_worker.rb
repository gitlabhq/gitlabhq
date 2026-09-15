# frozen_string_literal: true

module Ci
  class ExecuteBuildHooksWorker
    include ApplicationWorker

    data_consistency :delayed

    feature_category :pipeline_composition
    urgency :low

    idempotent!

    def perform(project_id, build_data_or_build_id, build_state = nil)
      project = Project.find_by_id(project_id)
      return unless project

      build_data = resolve_build_data(build_data_or_build_id, build_state)
      return unless build_data

      project.execute_hooks(build_data, :job_hooks) if project.has_active_hooks?(:job_hooks)
      project.execute_integrations(build_data, :job_hooks) if project.has_active_integrations?(:job_hooks)

      log_extra_metadata_on_done(:build_status, build_data[:build_status])
    end

    private

    def resolve_build_data(build_data_or_build_id, build_state)
      return build_data_or_build_id.with_indifferent_access if build_data_or_build_id.is_a?(Hash)

      build = Ci::Build.find_by_id(build_data_or_build_id)
      return unless build

      ActiveRecord::Associations::Preloader.new(records: [build], associations: { runner: :tags }).call

      Gitlab::DataBuilder::Build.build(build)
        .with_indifferent_access
        .merge(pinned_attributes(build_state))
    end

    def pinned_attributes(build_state)
      attributes = build_state.to_h.with_indifferent_access

      %w[build_started_at build_finished_at].each do |field|
        next unless attributes.key?(field)

        attributes["#{field}_iso"] = attributes[field]&.to_time&.utc&.iso8601
      end

      attributes
    end
  end
end
