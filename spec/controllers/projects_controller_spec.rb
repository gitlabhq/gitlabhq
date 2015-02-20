require('spec_helper')

describe ProjectsController do
  let(:project) { create(:project) }
  let(:public_project) { create(:project, :public) }
  let(:user)    { create(:user) }
  
  describe 'POST #toggle_star' do
    it 'toggles star if user is signed in' do
      sign_in(user)
      expect(user.starred?(public_project)).to be_falsey
      post :toggle_star, id: public_project.to_param
      expect(user.starred?(public_project)).to be_truthy
      post :toggle_star, id: public_project.to_param
      expect(user.starred?(public_project)).to be_falsey
    end

    it 'does nothing if user is not signed in' do
      post :toggle_star, id: public_project.to_param
      expect(user.starred?(public_project)).to be_falsey
      post :toggle_star, id: public_project.to_param
      expect(user.starred?(public_project)).to be_falsey
    end
  end
end
