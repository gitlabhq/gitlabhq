# frozen_string_literal: true

Pact.provider_states_for "MergeRequests#show" do
  provider_state "a merge request with diffs exists" do
    set_up do
      user = User.find_by(name: Provider::UsersHelper::CONTRACT_USER_NAME)
      namespace = create(:namespace, name: 'gitlab-org')
      project = create(:project, :custom_repo, name: 'gitlab-qa', namespace: namespace, files: {})

      project.add_maintainer(user)

      merge_request = create(:merge_request_with_multiple_diffs, source_project: project)
      merge_request_diff = create(:merge_request_diff, merge_request: merge_request)

      create(:merge_request_diff_file, :new_file, merge_request_diff: merge_request_diff)
    end
  end

  provider_state "a merge request exists" do
    set_up do
      user = User.find_by(name: Provider::UsersHelper::CONTRACT_USER_NAME)
      namespace = create(:namespace, name: 'gitlab-org')
      project = create(:project, :custom_repo, name: 'gitlab-qa', namespace: namespace, files: {})

      project.add_maintainer(user)

      merge_request = create(:merge_request, source_project: project)
      merge_request_diff = create(:merge_request_diff, merge_request: merge_request)

      create(:merge_request_diff_file, :new_file, merge_request_diff: merge_request_diff)
    end
  end

  provider_state "a merge request with discussions exists" do
    set_up do
      user = User.find_by(name: Provider::UsersHelper::CONTRACT_USER_NAME)
      namespace = create(:namespace, name: 'gitlab-org')
      project = create(:project, name: 'gitlab-qa', namespace: namespace)

      project.add_maintainer(user)

      merge_request = create(:merge_request_with_diffs, source_project: project, author: user)

      create(:discussion_note_on_merge_request, noteable: merge_request, project: project, author: user)
    end
  end
end
