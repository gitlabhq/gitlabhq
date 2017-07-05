require 'rails_helper'

feature 'Geo clone instructions', feature: true, js: true do
  include Devise::Test::IntegrationHelpers

  let(:project) { create(:empty_project, :empty_repo) }
  let(:developer) { create(:user) }

  background do
    primary = create(:geo_node, :primary, schema: 'https', host: 'primary.domain.com', port: 443)
    primary.update_attribute(:clone_url_prefix, 'git@primary.domain.com:')
    create(:geo_node, :current)
    allow(Gitlab::Geo).to receive(:secondary?).and_return(true)

    project.team << [developer, :developer]
    sign_in(developer)
  end

  context 'with an SSH key' do
    background do
      create(:personal_key, user: developer)
    end

    scenario 'defaults to SSH' do
      visit_project

      show_geo_clone_instructions

      expect_instructions_for('ssh')
    end

    scenario 'switches to HTTP' do
      visit_project
      select_protocol('HTTP')

      show_geo_clone_instructions

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

  def show_geo_clone_instructions
    find('.btn-geo').click
  end

  def expect_instructions_for(protocol)
    primary_remote = primary_url(protocol)
    secondary_remote = secondary_url(protocol)

    expect(page).to have_content('How to work faster with Geo')
    expect(page).to have_content("git clone #{secondary_remote}")
    expect(page).to have_content("git remote set-url --push origin #{primary_remote}")
  end

  def primary_url(protocol)
    case protocol
    when 'ssh'
      'git@primary.domain.com:'
    when 'http'
      'https://primary.domain.com'
    end
  end

  def secondary_url(protocol)
    case protocol
    when 'ssh'
      project.ssh_url_to_repo
    when 'http'
      project.http_url_to_repo
    end
  end
end
