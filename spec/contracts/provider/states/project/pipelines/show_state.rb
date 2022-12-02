# frozen_string_literal: true

Pact.provider_states_for "Pipelines#show" do
  provider_state "a pipeline for a project exists" do
    set_up do
      user = User.find_by(name: Provider::UsersHelper::CONTRACT_USER_NAME)
      namespace = create(:namespace, name: 'gitlab-org')
      project = create(:project, :repository, name: 'gitlab-qa', namespace: namespace, creator: user)
      scheduled_job = create(:ci_build, :scheduled)
      manual_job = create(:ci_build, :manual)

      project.add_maintainer(user)

      create(
        :ci_pipeline,
        :with_job,
        :success,
        id: 316112,
        iid: 1,
        project: project,
        user: user,
        duration: 10,
        finished_at: '2022-06-01T02:47:31.432Z',
        builds: [scheduled_job, manual_job]
      )
    end
  end
end
