require 'spec_helper'

describe Search::GroupService do
  shared_examples_for 'group search' do
    context 'finding projects by name' do
      let(:user) { create(:user) }
      let(:term) { "Project Name" }
      let(:nested_group) { create(:group, :nested) }

      # These projects shouldn't be found
      let!(:outside_project) { create(:project, :public, name: "Outside #{term}") }
      let!(:private_project) { create(:project, :private, namespace: nested_group, name: "Private #{term}" )}
      let!(:other_project)   { create(:project, :public, namespace: nested_group, name: term.reverse) }

      # These projects should be found
      let!(:project1) { create(:project, :internal, namespace: nested_group, name: "Inner #{term} 1") }
      let!(:project2) { create(:project, :internal, namespace: nested_group, name: "Inner #{term} 2") }
      let!(:project3) { create(:project, :internal, namespace: nested_group.parent, name: "Outer #{term}") }

      let(:results) { described_class.new(user, search_group, search: term).execute }
      subject { results.objects('projects') }

      context 'in parent group' do
        let(:search_group) { nested_group.parent }

        it { is_expected.to match_array([project1, project2, project3]) }
      end

      context 'in subgroup' do
        let(:search_group) { nested_group }

        it { is_expected.to match_array([project1, project2]) }
      end
    end
  end

  describe 'elasticsearch' do
    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
      Gitlab::Elastic::Helper.create_empty_index

      # Ensure these are present when the index is refreshed
      _ = [
        outside_project, private_project, other_project,
        project1, project2, project3
      ]

      Gitlab::Elastic::Helper.refresh_index
    end

    after do
      Gitlab::Elastic::Helper.delete_index
    end

    include_examples 'group search'
  end
end
