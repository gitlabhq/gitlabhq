require 'rails_helper'

feature 'Developer views empty project instructions' do
  let(:project) { create(:project, :empty_repo) }
  let(:developer) { create(:user) }

  background do
    project.add_developer(developer)

    sign_in(developer)
  end

  context 'without an SSH key' do
    scenario 'defaults to HTTP' do
      visit_project

      expect_instructions_for('http')
    end

    scenario 'switches to SSH', :js do
      visit_project

      select_protocol('SSH')

      expect_instructions_for('ssh')
    end
  end

  context 'with an SSH key' do
    background do
      create(:personal_key, user: developer)
    end

    scenario 'defaults to SSH' do
      visit_project

      expect_instructions_for('ssh')
    end

    scenario 'switches to HTTP', :js do
      visit_project

      select_protocol('HTTP')

      expect_instructions_for('http')
    end
  end

  def visit_project
    visit project_path(project)
  end

  def select_protocol(protocol)
    find('#clone-dropdown').click
    find(".#{protocol.downcase}-selector").click
  end

  def expect_instructions_for(protocol)
    msg = :"#{protocol.downcase}_url_to_repo"

    expect(page).to have_content("git clone #{project.send(msg)}")
  end
end
