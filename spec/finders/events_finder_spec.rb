# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventsFinder do
  let_it_be(:user) { create(:user) }
  let(:private_user) { create(:user, private_profile: true) }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:project1) { create(:project, :private, creator_id: user.id, namespace: user.namespace) }
  let_it_be(:project2) { create(:project, :private, creator_id: user.id, namespace: user.namespace) }

  let_it_be(:closed_issue) { create(:closed_issue, project: project1, author: user) }
  let_it_be(:opened_merge_request) { create(:merge_request, source_project: project2, author: user) }
  let_it_be(:closed_issue_event) do
    create(:event, :closed, project: project1, author: user, target: closed_issue, created_at: Date.new(2016, 12, 30))
  end

  let_it_be(:opened_merge_request_event) do
    create(:event, :created, project: project2, author: user, target: opened_merge_request,
      created_at: Date.new(2017, 1, 31))
  end

  let_it_be(:closed_issue_event2) do
    create(:event, :closed, project: project1, author: user, target: closed_issue, created_at: Date.new(2016, 2, 2))
  end

  let_it_be(:opened_merge_request_event2) do
    create(:event, :created, project: project2, author: user, target: opened_merge_request,
      created_at: Date.new(2017, 2, 2))
  end

  let_it_be(:opened_merge_request3) { create(:merge_request, source_project: project1, author: other_user) }
  let_it_be(:other_developer_event) do
    create(:event, :created, project: project1, author: other_user, target: opened_merge_request3)
  end

  let_it_be(:public_project, freeze: false) do
    create(:project, :public, creator_id: user.id, namespace: user.namespace)
  end

  let_it_be(:confidential_issue) { create(:closed_issue, confidential: true, project: public_project, author: user) }
  let_it_be(:confidential_event) do
    create(:event, :closed, project: public_project, author: user, target: confidential_issue)
  end

  context 'when targeting a user' do
    it 'returns events between specified dates filtered on action and type' do
      events = described_class.new(source: user, current_user: user, action: 'created', target_type: 'merge_request',
        after: Date.new(2017, 1, 1), before: Date.new(2017, 2, 1)).execute

      expect(events).to eq([opened_merge_request_event])
    end

    it 'does not return events the current_user does not have access to' do
      events = described_class.new(source: user, current_user: other_user).execute

      expect(events).not_to include(opened_merge_request_event)
    end

    it 'does not include events on confidential issues the user does not have access to' do
      events = described_class.new(source: user, current_user: other_user).execute

      expect(events).not_to include(confidential_event)
    end

    it 'includes confidential events user has access to' do
      public_project.add_developer(other_user)
      events = described_class.new(source: user, current_user: other_user).execute

      expect(events).to include(confidential_event)
    end

    it 'returns nothing when the current user cannot read cross project' do
      expect(Ability).to receive(:allowed?).with(user, :read_cross_project).and_return(false)

      events = described_class.new(source: user, current_user: user).execute

      expect(events).to be_empty
    end

    it 'returns nothing when the target profile is private' do
      events = described_class.new(source: private_user, current_user: other_user).execute

      expect(events).to be_empty
    end
  end

  describe 'wiki events' do
    let_it_be(:events, freeze: false) { create_list(:wiki_page_event, 3, project: public_project) }

    subject(:finder) { described_class.new(source: public_project, target_type: 'wiki', current_user: user) }

    it 'can find the wiki events' do
      expect(finder.execute).to match_array(events)
    end
  end

  context 'dashboard events' do
    before_all do
      project1.add_developer(other_user)
    end

    context 'scope is `all`' do
      it 'includes activity of other users' do
        events = described_class.new(source: user, current_user: user, scope: 'all').execute

        expect(events).to include(other_developer_event)
      end
    end

    context 'scope is not `all`' do
      it 'does not include activity of other users' do
        events = described_class.new(source: user, current_user: user, scope: '').execute

        expect(events).not_to include(other_developer_event)
      end
    end
  end

  context 'when targeting a project' do
    it 'returns project events between specified dates filtered on action and type' do
      events = described_class.new(source: project1, current_user: user, action: 'closed', target_type: 'issue',
        after: Date.new(2016, 12, 1), before: Date.new(2017, 1, 1)).execute

      expect(events).to eq([closed_issue_event])
    end

    it 'does not return events the current_user does not have access to' do
      events = described_class.new(source: project2, current_user: other_user).execute

      expect(events).to be_empty
    end
  end

  context 'when target_type param is provided' do
    context 'when "project"' do
      let_it_be(:project) { public_project }

      let_it_be(:project_event) { create(:project_event, project: project, target: project) }
      let_it_be(:legacy_project_event) { create(:project_event, project: project, target: nil, action: :created) }

      let_it_be(:event_with_nil_target_type) { create(:event, project: project, target: nil, action: :closed) }
      let_it_be(:event_with_other_target_type) { create(:event, :for_issue, project: project) }

      subject { described_class.new(scope: 'all', current_user: user, target_type: 'project').execute }

      it { is_expected.to contain_exactly(project_event, legacy_project_event) }
      it { is_expected.not_to include(event_with_nil_target_type) }
      it { is_expected.not_to include(event_with_other_target_type) }
    end
  end

  describe '#by_organization', feature_category: :user_profile do
    let_it_be(:organization) { create(:organization) }
    let_it_be(:other_organization) { create(:organization) }

    let_it_be(:org_project) do
      create(:project, :public, organization: organization, creator_id: user.id)
    end

    let_it_be(:other_org_project) do
      create(:project, :public, organization: other_organization, creator_id: user.id)
    end

    let_it_be(:org_event) do
      create(:event, :created, project: org_project, author: user)
    end

    let_it_be(:other_org_event) do
      create(:event, :created, project: other_org_project, author: user)
    end

    context 'when organization is provided' do
      subject(:events) do
        described_class.new(
          source: user,
          current_user: user,
          organization: organization
        ).execute
      end

      it 'returns only events from the specified organization', :aggregate_failures do
        expect(events).to include(org_event)
        expect(events).not_to include(other_org_event)
      end

      it 'returns events from multiple projects in the same organization' do
        second_org_project = create(:project, :public, organization: organization, creator_id: user.id)
        second_org_event = create(:event, :created, project: second_org_project, author: user)

        expect(events).to include(org_event, second_org_event)
      end
    end

    context 'when organization is not provided' do
      subject(:events) do
        described_class.new(
          source: user,
          current_user: user
        ).execute
      end

      it 'returns events from all organizations', :aggregate_failures do
        expect(events).to include(org_event)
        expect(events).to include(other_org_event)
      end
    end

    it 'excludes group events due to project join in by_current_user_access', :aggregate_failures do
      # Group events have project_id = NULL, so they are excluded by the
      # INNER JOIN on projects in by_current_user_access. The in_organization
      # scope supports group events, but EventsFinder filters them out earlier.
      org_group = create(:group, organization: organization)
      other_org_group = create(:group, organization: other_organization)
      org_group_event = create(:event, :created, group: org_group, project: nil, author: user)
      other_org_group_event = create(:event, :created, group: other_org_group, project: nil, author: user)

      events = described_class.new(
        source: user,
        current_user: user,
        organization: organization
      ).execute

      expect(events).not_to include(org_group_event)
      expect(events).not_to include(other_org_group_event)
    end
  end
end
