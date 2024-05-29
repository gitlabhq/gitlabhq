# frozen_string_literal: true

class DetailedStatusEntity < Grape::Entity
  include RequestAwareEntity

  expose :icon, documentation: { type: 'string', example: 'status_success' }
  expose :text, documentation: { type: 'string', example: 'passed' }
  expose :label, documentation: { type: 'string', example: 'passed' }
  expose :group, documentation: { type: 'string', example: 'success' }
  expose :status_tooltip, as: :tooltip, documentation: { type: 'string', example: 'passed' }
  expose :has_details?, as: :has_details, documentation: { type: 'boolean', example: true }
  expose :details_path, documentation: { type: 'string', example: '/test-group/test-project/-/pipelines/287' }

  expose :illustration, documentation: {
    type: 'object',
    example: <<~JSON
      {
        "image": "illustrations/empty-state/empty-job-not-triggered-md.svg",
        "size": "",
        "title": "This job has not been triggered yet",
        "content": "This job depends on upstream jobs that need to succeed in order for this job to be triggered"
      }
    JSON
  } do |status|
    illustration = {
      image: ActionController::Base.helpers.image_path(status.illustration[:image])
    }
    illustration = status.illustration.merge(illustration)

    illustration
  rescue NotImplementedError
    # ignored
  end

  expose :favicon,
    documentation: { type: 'string',
                     example: '/assets/ci_favicons/favicon_status_success.png' } do |status|
    Gitlab::Favicon.ci_status_overlay(status.favicon)
  end

  expose :action, if: ->(status, _) { status.has_action? } do
    expose :action_icon, as: :icon, documentation: { type: 'string', example: 'cancel' }
    expose :action_title, as: :title, documentation: { type: 'string', example: 'Cancel' }
    expose :action_path, as: :path, documentation: { type: 'string', example: '/namespace1/project1/-/jobs/2/cancel' }
    expose :action_method, as: :method, documentation: { type: 'string', example: 'post' }
    expose :action_button_title, as: :button_title, documentation: { type: 'string', example: 'Cancel this job' }
    expose :confirmation_message, as: :confirmation_message, documentation: { type: 'string', example: 'Are you sure?' }
  end
end
