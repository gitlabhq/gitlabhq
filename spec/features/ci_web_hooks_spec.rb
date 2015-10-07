require 'spec_helper'

describe 'CI web hooks' do
  let(:user) { create(:user) }
  before { login_as(user) }

  before do
    @project = FactoryGirl.create :ci_project
    @gl_project = @project.gl_project
    @gl_project.team << [user, :master]
    visit namespace_project_ci_web_hooks_path(@gl_project.namespace, @gl_project)
  end

  context 'create a trigger' do
    before do
      fill_in 'web_hook_url', with: 'http://example.com'
      click_on 'Add Web Hook'
    end

    it { expect(@project.web_hooks.count).to eq(1) }

    it 'revokes the trigger' do
      click_on 'Remove'
      expect(@project.web_hooks.count).to eq(0)
    end
  end
end
