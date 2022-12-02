# frozen_string_literal: true

Pact.provider_states_for "Pipelines#new" do
  provider_state "a project with a valid .gitlab-ci.yml configuration exists" do
    set_up do
      user = User.find_by(name: Provider::UsersHelper::CONTRACT_USER_NAME)
      namespace = create(:namespace, name: 'gitlab-org')
      project = create(
        :project,
        :custom_repo,
        name: 'gitlab-qa',
        namespace: namespace,
        creator: user,
        files: {
          '.gitlab-ci.yml' => <<~YAML
            test-success:
              script: echo 'OK'
          YAML
        })

      project.add_maintainer(user)
    end
  end
end
