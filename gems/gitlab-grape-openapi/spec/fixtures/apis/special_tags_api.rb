# frozen_string_literal: true

# rubocop:disable API/Base -- Test fixture
module TestApis
  class SpecialTagsApi < Grape::API
    # rubocop:disable API/DescriptionDetail          -- Class needed only to test edge cases in the tags
    # rubocop:disable API/DescriptionSuccessResponse -- Class needed only to test edge cases in the tags
    desc 'Endpoint with a numeric tag' do
      tags ['123numeric']
    end
    get '/api/:version/numeric' do
      { message: 'numeric' }
    end

    desc 'Endpoint with hyphens' do
      tags ['-api-v2']
    end
    get '/api/:version/hyphen' do
      { message: 'special' }
    end

    desc 'Endpoint with underscores' do
      tags ['_user_management']
    end
    get '/api/:version/underscore' do
      { message: 'underscore' }
    end

    desc 'Endpoint with camel case' do
      tags ['AdminPanel']
    end
    get '/api/:version/camel' do
      { message: 'camel' }
    end

    # rubocop:enable API/DescriptionSuccessResponse
    # rubocop:enable API/DescriptionDetail
  end
end
# rubocop:enable API/Base
