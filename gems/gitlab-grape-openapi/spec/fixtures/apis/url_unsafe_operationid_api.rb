# frozen_string_literal: true

# rubocop:disable API/Base -- Test fixture
module TestApis
  class UrlUnsafeOperationidApi < Grape::API
    desc 'Optional dash segment'
    get '/api/:version/groups/:id/(-/)epics' do
      status 200
    end

    desc 'Optional parameter segment'
    get '/api/:version/vscode/settings_sync(/:settings_context_hash)/v1/manifest' do
      status 200
    end

    desc 'Escaped parentheses'
    get '/api/:version/projects/:project_id/packages/nuget/v2/FindPackagesById\(\)' do
      status 200
    end

    desc 'Dollar sign in path'
    get '/api/:version/projects/:id/packages/nuget/v2/$metadata' do
      status 200
    end

    desc 'Parameter adjacent to extension'
    get '/api/:version/projects/:id/packages/helm/:channel/charts/:file_name.tgz' do
      status 200
    end

    desc 'Optional ref segment'
    post '/api/:version/projects/:id/(ref/:ref/)trigger/pipeline' do
      status 201
    end
  end
end
# rubocop:enable API/Base
