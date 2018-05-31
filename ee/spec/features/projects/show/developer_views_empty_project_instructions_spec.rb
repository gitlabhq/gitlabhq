require 'rails_helper'

feature 'Projects > Show > Developer views empty project instructions' do
  let(:project) { create(:project, :empty_repo) }
  let(:developer) { create(:user) }

  background do
    project.add_developer(developer)

    sign_in(developer)
  end

  context 'with Kerberos enabled' do
    background do
      allow(Gitlab.config.kerberos).to receive(:enabled).and_return(true)
    end

    scenario 'defaults to KRB5' do
      visit project_path(project)

      expect(page).to have_content("git clone #{project.kerberos_url_to_repo}")
    end
  end
end
