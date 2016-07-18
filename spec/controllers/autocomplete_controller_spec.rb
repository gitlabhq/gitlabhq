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
      project.team << [user2, :developer]
    end

    describe 'GET #users with project ID' do
      before do
        get(:users, project_id: project.id)
      end

      let(:body) { JSON.parse(response.body) }

      it { expect(body).to be_kind_of(Array) }
      it { expect(body.size).to eq 2 }
      it { expect(body.map { |u| u["username"] }).to include(user.username) }
    end

    describe 'GET #users with unknown project' do
      before do
        get(:users, project_id: 'unknown')
      end

      it { expect(response).to have_http_status(404) }
    end

    describe "GET #users that can push to protected branches" do
      before do
        get(:users, project_id: project.id, push_code_to_protected_branches: 'true')
      end

      let(:body) { JSON.parse(response.body) }

      it { expect(body).to be_kind_of(Array) }
      it { expect(body.size).to eq 1 }
      it { expect(body.first["username"]).to eq user.username }
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

      it { expect(response).to have_http_status(404) }
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

      it { expect(response).to have_http_status(404) }
    end

    describe 'GET #users with unknown project' do
      before do
        get(:users, project_id: 'unknown')
      end

      it { expect(response).to have_http_status(404) }
    end

    describe 'GET #users with inaccessible group' do
      before do
        project.team << [user, :guest]
        get(:users, group_id: user.namespace.id)
      end

      it { expect(response).to have_http_status(404) }
    end

    describe 'GET #users with no project' do
      before do
        get(:users)
      end

      it { expect(body).to be_kind_of(Array) }
      it { expect(body.size).to eq 0 }
    end
  end

  context 'author of issuable included' do
    before do
      sign_in(user)
    end

    let(:body) { JSON.parse(response.body) }

    it 'includes the author' do
      get(:users, author_id: non_member.id)

      expect(body.first["username"]).to eq non_member.username
    end

    it 'rejects non existent user ids' do
      get(:users, author_id: 99999)

      expect(body.collect { |u| u['id'] }).not_to include(99999)
    end
  end

  context 'skip_users parameter included' do
    before { sign_in(user) }

    let(:response_user_ids) { JSON.parse(response.body).map { |user| user['id'] } }

    it 'skips the user IDs passed' do
      get(:users, skip_users: [user, user2].map(&:id))

      expect(response_user_ids).not_to include(user.id)
      expect(response_user_ids).not_to include(user2.id)
      expect(response_user_ids).not_to be_empty
    end
  end
end
