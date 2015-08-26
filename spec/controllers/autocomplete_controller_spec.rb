require 'spec_helper'

describe AutocompleteController do
  let!(:project) { create(:project) }
  let!(:user)    { create(:user) }
  let!(:user2)   { create(:user) }
  let!(:non_member)   { create(:user) }

  context 'project members' do
    before do
      sign_in(user)
      project.team << [user, :master]
    end

    let(:body) { JSON.parse(response.body) }

    describe 'GET #users with project ID' do
      before do
        get(:users, project_id: project.id)
      end

      it { expect(body).to be_kind_of(Array) }
      it { expect(body.size).to eq 1 }
      it { expect(body.first["username"]).to eq user.username }
    end

    describe 'GET #users with unknown project' do
      before do
        get(:users, project_id: 'unknown')
      end

      it { expect(response.status).to eq(404) }
    end
  end

  context 'group members' do
    let(:group) { create(:group) }

    before do
      sign_in(user)
      group.add_owner(user)
    end

    let(:body) { JSON.parse(response.body) }

    describe 'GET #users with group ID' do
      before do
        get(:users, group_id: group.id)
      end

      it { expect(body).to be_kind_of(Array) }
      it { expect(body.size).to eq 1 }
      it { expect(body.first["username"]).to eq user.username }
    end

    describe 'GET #users with unknown group ID' do
      before do
        get(:users, group_id: 'unknown')
      end

      it { expect(response.status).to eq(404) }
    end
  end

  context 'non-member login for public project' do
    let!(:project) { create(:project, :public) }

    before do
      sign_in(non_member)
      project.team << [user, :master]
    end

    let(:body) { JSON.parse(response.body) }

    describe 'GET #users with project ID' do
      before do
        get(:users, project_id: project.id, current_user: true)
      end

      it { expect(body).to be_kind_of(Array) }
      it { expect(body.size).to eq 2 }
      it { expect(body.map { |u| u['username'] }).to match_array([user.username, non_member.username]) }
    end
  end

  context 'all users' do
    before do
      sign_in(user)
      get(:users)
    end

    let(:body) { JSON.parse(response.body) }

    it { expect(body).to be_kind_of(Array) }
    it { expect(body.size).to eq User.count }
  end

  context 'unauthenticated user' do
    let(:public_project) { create(:project, :public) }
    let(:body) { JSON.parse(response.body) }

    describe 'GET #users with public project' do
      before do
        public_project.team << [user, :guest]
        get(:users, project_id: public_project.id)
      end

      it { expect(body).to be_kind_of(Array) }
      it { expect(body.size).to eq 1 }
    end

    describe 'GET #users with project' do
      before do
        get(:users, project_id: project.id)
      end

      it { expect(response.status).to eq(302) }
    end

    describe 'GET #users with unknown project' do
      before do
        get(:users, project_id: 'unknown')
      end

      it { expect(response.status).to eq(302) }
    end

    describe 'GET #users with inaccessible group' do
      before do
        project.team << [user, :guest]
        get(:users, group_id: user.namespace.id)
      end

      it { expect(response.status).to eq(302) }
    end

    describe 'GET #users with no project' do
      before do
        get(:users)
      end

      it { expect(response.status).to eq(302) }
    end
  end
end
