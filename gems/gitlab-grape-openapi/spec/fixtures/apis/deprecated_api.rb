# frozen_string_literal: true

# rubocop:disable API/Base -- Test fixture
module TestApis
  class DeprecatedApi < Grape::API
    desc 'Get resource with directive' do
      detail 'Uses deprecated flag'
      success TestEntities::UserEntity
      tags %w[deprecated_api]
      deprecated true
    end
    get '/api/:version/directive' do
      { message: 'directive' }
    end

    # Non-deprecated endpoint
    desc 'Get normal resource'
    get '/api/:version/normal' do
      { message: 'normal' }
    end
  end
end
# rubocop:enable API/Base
