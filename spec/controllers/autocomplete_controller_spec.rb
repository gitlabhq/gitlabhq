require 'spec_helper'

describe AutocompleteController do
  let!(:project) { create(:project) }
  let!(:user)    { create(:user) }
  let!(:user2)   { create(:user) }

  context 'project members' do
    before do
      sign_in(user)
      project.team << [user, :master]

      get(:users, project_id: project.id)
    end

    let(:body) { JSON.parse(response.body) }

    it { expect(body).to be_kind_of(Array) }
    it { expect(body.size).to eq 1 }
    it { expect(body.first["username"]).to eq user.username }
  end

  context 'group members' do
    let(:group) { create(:group) }

    before do
      sign_in(user)
      group.add_owner(user)

      get(:users, group_id: group.id)
    end

    let(:body) { JSON.parse(response.body) }

    it { expect(body).to be_kind_of(Array) }
    it { expect(body.size).to eq 1 }
    it { expect(body.first["username"]).to eq user.username }
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
    let(:project) { create(:project, :public) }
    let(:body) { JSON.parse(response.body) }

    describe 'GET #users with public project' do
      before do
        project.team << [user, :guest]
        get(:users, project_id: project.id)
      end

      it { expect(body).to be_kind_of(Array) }
      it { expect(body.size).to eq 1 }
    end

    describe 'GET #users with no project' do
      before do
        get(:users)
      end

      it { expect(body).to be_kind_of(Array) }
      it { expect(body.size).to eq 0 }
    end
  end
end
