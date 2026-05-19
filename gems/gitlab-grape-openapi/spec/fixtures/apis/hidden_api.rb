# frozen_string_literal: true

# rubocop:disable API/Base -- Test fixture
module TestApis
  class HiddenApi < Grape::API
    desc 'Get resource with directive' do
      detail 'Is marked as hidden'
      success TestEntities::UserEntity
      tags %w[deprecated_api]
      hidden true
    end
    get '/api/:version/hidden' do
      { message: 'directive' }
    end

    desc 'Create resource with directive' do
      detail 'Is marked as hidden'
      success TestEntities::UserEntity
      tags %w[deprecated_api]
      hidden true
    end
    params do
      requires :name, type: String, desc: 'Name'
      optional :description, type: String, desc: 'Description'
    end
    post '/api/:version/hidden' do
      { message: 'directive' }
    end
  end
end
# rubocop:enable API/Base
