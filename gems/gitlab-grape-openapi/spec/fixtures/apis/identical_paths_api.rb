# frozen_string_literal: true

# rubocop:disable API/Base -- Test fixture
module TestApis
  class IdenticalPathsApi < Grape::API
    desc 'Get item by item_id' do
      detail 'Downloads an item by its database ID'
      success TestEntities::UserEntity
      tags %w[items]
    end
    params do
      requires :id, type: Integer, desc: 'Parent ID'
      requires :item_id, type: Integer, desc: 'Item ID'
    end
    get '/api/:version/resources/:id/items/:item_id' do
      status 200
    end

    desc 'Create item by digest' do
      detail 'Creates an item identified by digest'
      success TestEntities::UserEntity
      tags %w[items]
    end
    params do
      requires :id, type: Integer, desc: 'Parent ID'
      requires :item_digest, type: String, desc: 'Item digest'
    end
    post '/api/:version/resources/:id/items/:item_digest' do
      status 201
    end
  end
end
# rubocop:enable API/Base
