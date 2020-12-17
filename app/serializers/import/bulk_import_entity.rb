# frozen_string_literal: true

class Import::BulkImportEntity < Grape::Entity
  expose :id do |entity|
    entity['id']
  end

  expose :full_name do |entity|
    entity['full_name']
  end

  expose :full_path do |entity|
    entity['full_path']
  end

  expose :web_url do |entity|
    entity['web_url']
  end
end
