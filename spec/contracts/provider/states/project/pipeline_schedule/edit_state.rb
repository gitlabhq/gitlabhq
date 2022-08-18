# frozen_string_literal: true

Pact.provider_states_for "PipelineSchedules#edit" do
  provider_state "a project with a pipeline schedule exists" do
    set_up do
      user = User.find_by(name: Provider::UsersHelper::CONTRACT_USER_NAME)
      namespace = create(:namespace, name: 'gitlab-org')
      project = create(:project, :repository, name: 'gitlab-qa', namespace: namespace, creator: user)

      project.add_maintainer(user)

      create(:ci_pipeline_schedule, id: 25, project: project, owner: user)
    end
  end
end
