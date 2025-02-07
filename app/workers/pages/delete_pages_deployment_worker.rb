# frozen_string_literal: true

module Pages
  class DeletePagesDeploymentWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :always
    feature_category :pages
    idempotent!

    def handle_event(event)
      project = Project.find_by_id(event.data['project_id'])
      return unless project

      user = project.owner
      return unless user

      ::Pages::DeleteService.new(project, user).execute
    end
  end
end
