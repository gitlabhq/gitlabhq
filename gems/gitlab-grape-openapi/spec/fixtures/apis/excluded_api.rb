# frozen_string_literal: true

# rubocop:disable API/Base -- Test fixture
module TestApis
  class ExcludedApi < Grape::API
    desc 'Get internal resource' do
      detail 'Internal, private and undocumented'
      success code: 200
      tags %w[excluded_api]
    end
    get '/api/:version/internal' do
      { message: 'internal only' }
    end
  end
end
# rubocop:enable API/Base
