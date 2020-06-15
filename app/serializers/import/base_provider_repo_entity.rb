# frozen_string_literal: true

class Import::BaseProviderRepoEntity < Grape::Entity
  expose :id
  expose :full_name
  expose :sanitized_name
  expose :provider_link
end
