module Events
  class CreatePushEvent < Interactor::Base
    def setup
      context.fail!(message: 'Invalid project') if context[:project].blank?
      context.fail!(message: 'Invalid push data') if context[:push_data].blank?
    end

    def perform
      project = context[:project]
      push_data = context[:push_data]

      context[:event] = Event.create!(
        project: project,
        action: Event::PUSHED,
        data: push_data,
        author_id: push_data[:user_id]
      )
    end

    def rollback
      context[:event].destroy
      context.delete(:event)
    end
  end
end
