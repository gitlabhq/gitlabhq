require 'spec_helper'

describe "CI settings" do
  let(:user) { create(:user) }
  before { login_as(user) }

  before do
    @project = FactoryGirl.create :ci_project
    @gl_project = @project.gl_project
    @gl_project.team << [user, :master]
    visit edit_namespace_project_ci_settings_path(@gl_project.namespace, @gl_project)
  end

  it { expect(page).to have_content 'Build Schedule' }

  it "updates configuration" do
    fill_in 'Timeout', with: '70'
    click_button 'Save changes'
    expect(page).to have_content 'was successfully updated'
    expect(find_field('Timeout').value).to eq '70'
  end
end
