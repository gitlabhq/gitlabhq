require 'spec_helper'

describe 'Projects > Show > Redirects' do
  let(:user) { create :user }
  let(:public_project) { create :project, :public }
  let(:private_project) { create :project, :private }

  before do
    allow(Gitlab.config.gitlab).to receive(:host).and_return('www.example.com')
  end

  it 'shows public project page' do
    visit project_path(public_project)

    page.within '.breadcrumbs .breadcrumb-item-text' do
      expect(page).to have_content(public_project.name)
    end
  end

  it 'redirects to sign in page when project is private' do
    visit project_path(private_project)

    expect(current_path).to eq(new_user_session_path)
  end

  it 'redirects to sign in page when project does not exist' do
    visit project_path(build(:project, :public))

    expect(current_path).to eq(new_user_session_path)
  end

  it 'redirects to public project page after signing in' do
    visit project_path(public_project)

    first(:link, 'Sign in').click

    fill_in 'user_login',    with: user.email
    fill_in 'user_password', with: user.password
    click_button 'Sign in'

    expect(status_code).to eq(200)
    expect(current_path).to eq("/#{public_project.full_path}")
  end

  it 'redirects to private project page after sign in' do
    visit project_path(private_project)

    owner = private_project.owner
    fill_in 'user_login',    with: owner.email
    fill_in 'user_password', with: owner.password
    click_button 'Sign in'

    expect(status_code).to eq(200)
    expect(current_path).to eq("/#{private_project.full_path}")
  end

  context 'when signed in' do
    before do
      sign_in(user)
    end

    it 'returns 404 status when project does not exist' do
      visit project_path(build(:project, :public))

      expect(status_code).to eq(404)
    end

    it 'returns 404 when project is private' do
      visit project_path(private_project)

      expect(status_code).to eq(404)
    end
  end
end
