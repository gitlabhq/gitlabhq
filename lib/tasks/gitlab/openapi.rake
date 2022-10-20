# frozen_string_literal: true

require 'logger'

if Rails.env.development?
  require 'grape-swagger/rake/oapi_tasks'
  GrapeSwagger::Rake::OapiTasks.new('::API::API')
end

namespace :gitlab do
  namespace :openapi do
    task :generate do
      raise 'This task can only be run in the development environment' unless Rails.env.development?

      ENV['store'] = 'tmp/openapi.json'
      Rake::Task["oapi:fetch"].invoke(['openapi.json'])

      yaml_content = Gitlab::Json.parse(File.read('tmp/openapi_swagger_doc.json')).to_yaml

      File.write("doc/api/openapi/openapi_v2.yaml", yaml_content)
    end
  end
end
