# frozen_string_literal: true

# rubocop:disable API/Base -- Test fixture
module TestApis
  class NestedApi < Grape::API
    desc 'No nesting'
    get '/api/:version/users' do
      status 200
      [
        { id: 1, name: 'John Doe', email: 'john@example.com' },
        { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
      ]
    end

    desc '1 level of nesting'
    get '/api/:version/admin/users' do
      status 200
      [
        { id: 1, name: 'Admin User', email: 'admin@example.com', role: 'admin' }
      ]
    end

    desc '2 levels of nesting (GET)'
    get '/api/:version/projects/:project_id/users' do
      status 200
      [
        { id: 1, name: 'Project Member', project_id: params[:project_id].to_i, role: 'developer' }
      ]
    end

    desc '2 levels of nesting (POST)'
    post '/api/:version/projects/:project_id/users' do
      status 201
      { id: params[:user_id].to_i, project_id: params[:project_id].to_i, role: params[:role] }
    end

    desc '2 levels of nesting with different resource'
    get '/api/:version/projects/:project_id/merge_requests' do
      status 200
      [
        { id: 1, title: 'Feature update', project_id: params[:project_id].to_i, state: 'open' }
      ]
    end

    desc '3 levels of nesting (GET)'
    get '/api/:version/projects/:project_id/merge_requests/:merge_request_id/comments' do
      status 200
      [
        { id: 1, body: 'Looks good!', merge_request_id: params[:merge_request_id].to_i }
      ]
    end

    desc '3 levels of nesting (POST)'
    post '/api/:version/projects/:project_id/merge_requests/:merge_request_id/comments' do
      status 201
      { id: 4, body: params[:body], merge_request_id: params[:merge_request_id].to_i }
    end
  end
end
# rubocop:enable API/Base
