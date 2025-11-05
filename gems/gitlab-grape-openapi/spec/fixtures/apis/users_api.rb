# frozen_string_literal: true

# rubocop:disable API/Base -- Test fixture
module TestApis
  class UsersApi < Grape::API
    desc 'Get all users' do
      detail 'Returns a list of all users'
      success TestEntities::UserEntity
      tags %w[users_api]
    end
    params do
      optional :active, type: Boolean, desc: 'Filter by active users'
      optional :username, type: String, desc: 'Find by username'
      optional :tag, type: String, regexp: /Hello/, desc: "Hello tag"
    end
    get '/api/:version/users' do
      status 200
      [
        { id: 1, name: 'John Doe', email: 'john@example.com' },
        { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
      ]
    end

    desc 'Create a user' do
      detail 'Creates a new user with the provided information'
      success code: 201, model: TestEntities::UserEntity
      tags %w[users_api]
    end
    post '/api/:version/users' do
      status 201
      { id: 3, name: params[:name], email: params[:email], created_at: '2025-10-20 15:55:15.465357 -0700' }
    end

    desc 'Update a user (full replacement)' do
      detail 'Replaces all user information with the provided data'
      success TestEntities::UserEntity
      tags %w[users_api]
    end
    put '/api/:version/users/:id' do
      status 200
      {
        id: params[:id].to_i,
        name: params[:name],
        email: params[:email],
        updated_at: '2025-10-20 15:55:15.465357 -0700'
      }
    end

    desc 'Update a user (partial)' do
      detail 'Updates only the specified user fields'
      success TestEntities::UserEntity
      tags %w[users_api]
    end
    patch '/api/:version/users/:id' do
      status 200
      { id: params[:id].to_i, name: params[:name], updated_at: '2025-10-20 15:55:15.465357 -0700' }
    end

    desc 'Delete a user' do
      detail 'Permanently removes a user from the system'
      success code: 204
      tags %w[users_api]
    end
    delete '/api/:version/users/:id' do
      status 204
      nil
    end

    desc 'Get user headers'
    head '/api/:version/users/:id' do
      status 200
      nil
    end

    desc 'Get available options' do
      success TestEntities::UserEntity
      detail 'Gets available options'
      tags ['users']
    end
    options '/api/:version/users' do
      status 200
      header 'Allow', 'GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS'
      nil
    end
  end
end
# rubocop:enable API/Base
