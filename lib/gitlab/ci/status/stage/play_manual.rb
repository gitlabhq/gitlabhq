# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Stage
        class PlayManual < Status::Extended
          include Gitlab::Routing

          def action_icon
            'play'
          end

          def action_title
            'Run all manual'
          end

          def action_path
            pipeline = subject.pipeline

            project_pipeline_stage_play_manual_path(pipeline.project, pipeline, subject.name)
          end

          def action_method
            :post
          end

          def action_button_title
            _('Run all manual')
          end

          def self.matches?(stage, user)
            stage.manual_playable?
          end

          def confirmation_message
            return unless subject.confirm_manual_job?

            _('This stage has one or more manual jobs that require ' \
              'confirmation before retrying. Do you want to proceed?')
          end

          def has_action?
            true
          end
        end
      end
    end
  end
end
