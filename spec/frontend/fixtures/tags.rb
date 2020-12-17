# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Tags (JavaScript fixtures)' do
  include JavaScriptFixturesHelpers

  let_it_be(:project) { create(:project, :repository, path: 'tags-project') }
  let_it_be(:user) { project.owner }

  before(:all) do
    clean_frontend_fixtures('api/tags/')
  end

  after(:all) do
    remove_repository(project)
  end

  describe API::Tags, '(JavaScript fixtures)', type: :request do
    include ApiHelpers

    it 'api/tags/tags.json' do
      get api("/projects/#{project.id}/repository/tags", user)

      expect(response).to be_successful
    end
  end
end
