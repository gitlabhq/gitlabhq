# frozen_string_literal: true

require 'spec_helper'

describe 'admin visits dashboard' do
  include ProjectForksHelper

  before do
    sign_in(create(:admin))
  end

  context 'counting forks' do
    it 'correctly counts 2 forks of a project' do
      project = create(:project)
      project_fork = fork_project(project)
      fork_project(project_fork)

      # Make sure the fork_networks & fork_networks reltuples have been updated
      # to get a correct count on postgresql
      ActiveRecord::Base.connection.execute('ANALYZE fork_networks')
      ActiveRecord::Base.connection.execute('ANALYZE fork_network_members')

      visit admin_root_path

      expect(page).to have_content('Forks 2')
    end
  end
end
