require 'spec_helper'

describe "Projects" do
  let(:user)    { create(:user) }

  before do
    login_as(user)
    @project = FactoryGirl.create :ci_project, name: "GitLab / gitlab-shell"
    @project.gl_project.team << [user, :master]
  end

  describe "GET /ci/projects/:id" do
    before do
      visit ci_project_path(@project)
    end

    it { expect(page).to have_content @project.name }
    it { expect(page).to have_content 'All commits' }
  end

  describe "GET /ci/projects/:id/edit" do
    before do
      visit edit_ci_project_path(@project)
    end

    it { expect(page).to have_content @project.name }
    it { expect(page).to have_content 'Build Schedule' }

    it "updates configuration" do
      fill_in 'Timeout', with: '70'
      click_button 'Save changes'

      expect(page).to have_content 'was successfully updated'

      expect(find_field('Timeout').value).to eq '70'
    end
  end
end
