# frozen_string_literal: true

module API
  module Entities
    module Ml
      module Mlflow
        class RunInfo < Grape::Entity
          expose :run_id
          expose :run_id, as: :run_uuid
          expose(:experiment_id) { |candidate| candidate.experiment.iid.to_s }
          expose(:start_time) { |candidate| candidate.start_time || 0 }
          expose :end_time, expose_nil: false
          expose :name, as: :run_name, expose_nil: false
          expose(:status) { |candidate| candidate.status.to_s.upcase }
          expose(:artifact_uri) { |candidate, options| "#{options[:packages_url]}#{candidate.artifact_root}" }
          expose(:lifecycle_stage) { |candidate| 'active' }
          expose(:user_id) { |candidate| candidate.user_id.to_s }

          private

          def run_id
            object.eid.to_s
          end
        end
      end
    end
  end
end
