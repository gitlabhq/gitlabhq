# frozen_string_literal: true

# rubocop:disable API/Base -- Test fixture
module TestApis
  class SuccessKeywordApi < Grape::API
    desc 'Read a person via success keyword Hash form' do
      detail 'Returns a person resource'
      tags %w[persons_api]
      success code: 200, model: TestEntities::User::PersonEntity
    end
    get '/api/:version/persons' do
      {}
    end

    desc 'Create a person via success keyword Array form' do
      detail 'Creates a person resource'
      tags %w[persons_api]
      success [
        { code: 201, model: TestEntities::User::PersonEntity, message: 'Created' }
      ]
    end
    params do
      requires :name, type: String, desc: 'Person name'
    end
    post '/api/:version/persons' do
      {}
    end
  end
end
# rubocop:enable API/Base
