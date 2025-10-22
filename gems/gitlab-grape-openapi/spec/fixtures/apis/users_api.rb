# frozen_string_literal: true

# rubocop:disable API/Base -- Test fixture
module TestApis
  class UsersApi < Grape::API
    desc 'Get all users'
    get '/api/:version/users' do
      status 200
      [
        { id: 1, name: 'John Doe', email: 'john@example.com' },
        { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
      ]
    end

    desc 'Create a user'
    post '/api/:version/users' do
      status 201
      { id: 3, name: params[:name], email: params[:email], created_at: '2025-10-20 15:55:15.465357 -0700' }
    end

    desc 'Update a user (full replacement)'
    put '/api/:version/users/:id' do
      status 200
      {
        id: params[:id].to_i,
        name: params[:name],
        email: params[:email],
        updated_at: '2025-10-20 15:55:15.465357 -0700'
      }
    end

    desc 'Update a user (partial)'
    patch '/api/:version/users/:id' do
      status 200
      { id: params[:id].to_i, name: params[:name], updated_at: '2025-10-20 15:55:15.465357 -0700' }
    end

    desc 'Delete a user'
    delete '/api/:version/users/:id' do
      status 204
      nil
    end

    desc 'Get user headers'
    head '/api/:version/users/:id' do
      status 200
      nil
    end

    desc 'Get available options'
    options '/api/:version/users' do
      status 200
      header 'Allow', 'GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS'
      nil
    end
  end
end
# rubocop:enable API/Base
