# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContributedProjectsFinder, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:user_2) { create(:user) }
  let_it_be(:public_project) { create(:project, :public, name: 'foo') }
  let_it_be(:private_project) { create(:project, :private, name: 'bar') }
  let_it_be(:internal_project) { create(:project, :internal, name: 'baz') }

  let(:params) { {} }
  let(:source_user) { user }
  let(:current_user) { user_2 }
  let(:finder) { described_class.new(user: source_user, current_user: current_user, params: params) }

  let(:default_ordering) { [internal_project, private_project, public_project] }

  before_all do
    private_project.add_maintainer(user)
    private_project.add_developer(user_2)
    public_project.add_maintainer(user)

    travel_to(4.hours.from_now) { create(:push_event, project: private_project, author: user) }
    travel_to(3.hours.from_now) { create(:push_event, project: internal_project, author: user) }
    travel_to(2.hours.from_now) { create(:push_event, project: public_project, author: user) }
  end

  context 'when sort is specified' do
    let(:params) { { sort: 'latest_activity_desc' } }

    subject { finder.execute }

    it { is_expected.to eq([private_project, internal_project, public_project]) }
  end

  describe 'activity without a current user' do
    let(:current_user) { nil }

    it 'does only return public projects' do
      projects = finder.execute
      expect(projects).to match_array([public_project])
    end

    context 'when ignore_visibility is true' do
      let(:params) { { ignore_visibility: true } }

      it 'returns all projects' do
        projects = finder.execute
        expect(projects).to eq(default_ordering)
      end
    end
  end

  describe 'activity with a current user' do
    subject { finder.execute }

    it { is_expected.to eq(default_ordering) }
  end

  context 'user with private profile' do
    let_it_be(:private_user) { create(:user, private_profile: true) }
    let_it_be(:push_event) { create(:push_event, project: public_project, author: private_user) }

    let(:source_user) { private_user }

    before_all do
      public_project.add_maintainer(private_user)
    end

    it 'does not return contributed projects' do
      projects = finder.execute

      expect(projects).to be_empty
    end
  end

  describe 'with search param' do
    let(:params) { { search: 'foo' } }

    subject { finder.execute }

    it { is_expected.to eq([public_project]) }
  end

  describe 'with min_access_level param' do
    let_it_be(:project_with_owner_access) { create(:project, :private) }

    before_all do
      project_with_owner_access.add_owner(user)
      project_with_owner_access.add_owner(user_2)
      travel_to(4.hours.from_now) { create(:push_event, project: project_with_owner_access, author: user) }
    end

    context 'when min_access_level is OWNER' do
      let(:params) { { min_access_level: Gitlab::Access::OWNER } }

      it 'returns only projects user has owner access to' do
        projects = finder.execute

        expect(projects).to eq([project_with_owner_access])
      end
    end

    context 'when min_access_level is DEVELOPER' do
      let(:params) { { min_access_level: Gitlab::Access::DEVELOPER } }

      it 'returns only projects user has developer or higher access to' do
        projects = finder.execute

        expect(projects).to eq([project_with_owner_access, private_project])
      end
    end
  end

  context 'with programming_language_name param' do
    let_it_be(:ruby) { create(:programming_language, name: 'Ruby') }
    let_it_be(:repository_language) do
      create(:repository_language, project: internal_project, programming_language: ruby)
    end

    subject { finder.execute }

    context 'when programming_language_name is set to an existing language' do
      let(:params) { { programming_language_name: 'ruby' } }

      it { is_expected.to match_array([internal_project]) }
    end

    context 'when programming_language_name is an empty string' do
      let(:params) { { programming_language_name: '' } }

      it { is_expected.to match_array(default_ordering) }
    end
  end
end
