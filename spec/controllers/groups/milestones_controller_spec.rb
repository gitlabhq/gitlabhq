require 'spec_helper'

describe Groups::MilestonesController do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:project2) { create(:empty_project, group: group) }
  let(:user)    { create(:user) }
  let(:title) { '肯定不是中文的问题' }

  before do
    controller.instance_variable_set(:@group, group)
  end

  context 'unauthenticated user' do
    describe "#show" do
      it "should display milestone" do
        create(:milestone, title: title, project: project)

        get :show,
          group_id: group.id,
          id: title,
          title: title

        expect(response).to be_success
      end
    end
  end

  context 'project owner' do
    before do
      sign_in(user)
      group.add_owner(user)
      project.team << [user, :master]
    end

    describe "#create" do
      it "should create group milestone with Chinese title" do
        post :create,
             group_id: group.id,
             milestone: { project_ids: [project.id, project2.id], title: title }

        expect(response).to redirect_to(group_milestone_path(group, title.to_slug.to_s, title: title))
        expect(Milestone.where(title: title).count).to eq(2)
      end
    end
  end
end
