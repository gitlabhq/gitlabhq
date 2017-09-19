require 'spec_helper'

describe AutocompleteController do
  let(:project) { create(:project) }
  let(:user) { project.owner }

  context 'GET users' do
    let!(:user2) { create(:user) }
    let!(:non_member) { create(:user) }

    context 'project members' do
      before do
        project.add_developer(user2)
        sign_in(user)
      end

      describe "GET #users that can push to protected branches" do
        before do
          get(:users, project_id: project.id, push_code_to_protected_branches: 'true')
        end

        it 'returns authorized users', :aggregate_failures do
          expect(json_response).to be_kind_of(Array)
          expect(json_response.size).to eq(1)
          expect(json_response.map { |u| u["username"] }).to match_array([user.username])
        end
      end

      describe "GET #users that can push code" do
        let(:reporter_user) { create(:user) }

        before do
          project.add_reporter(reporter_user)
          get(:users, project_id: project.id, push_code: 'true')
        end

        it 'returns authorized users', :aggregate_failures do
          expect(json_response).to be_kind_of(Array)
          expect(json_response.size).to eq(2)
          expect(json_response.map { |user| user["username"] }).to match_array([user.username, user2.username])
        end
      end

      describe "GET #users that can push to protected branches, including the current user" do
        before do
          get(:users, project_id: project.id, push_code_to_protected_branches: true, current_user: true)
        end

        it 'returns authorized users', :aggregate_failures do
          expect(json_response).to be_kind_of(Array)
          expect(json_response.size).to eq(1)
          expect(json_response.map { |u| u["username"] }).to match_array([user.username])
        end
      end
    end
  end

  context "groups" do
    let(:matching_group) { create(:group) }
    let(:non_matching_group) { create(:group) }
    let(:user2) { create(:user) }

    before do
      project.invited_groups << matching_group
    end

    context "while fetching all groups belonging to a project" do
      before do
        sign_in(user)
        get(:project_groups, project_id: project.id)
      end

      it 'returns a single group', :aggregate_failures do
        expect(json_response).to be_kind_of(Array)
        expect(json_response.size).to eq(1)
        expect(json_response.first.values_at('id', 'name')).to eq [matching_group.id, matching_group.name]
      end
    end

    context "while fetching all groups belonging to a project the current user cannot access" do
      before do
        sign_in(user2)
        get(:project_groups, project_id: project.id)
      end

      it { expect(response).to be_not_found }
    end

    context "while fetching all groups belonging to an invalid project ID" do
      before do
        sign_in(user)
        get(:project_groups, project_id: 'invalid')
      end

      it { expect(response).to be_not_found }
    end
  end
end
