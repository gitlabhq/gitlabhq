# frozen_string_literal: true

if Rails.env.development?
  require 'grape-swagger/rake/oapi_tasks'
  GrapeSwagger::Rake::OapiTasks.new('::API::API')
end

namespace :gitlab do
  require 'logger'

  namespace :openapi do
    task :validate do
      raise 'This task can only be run in the development environment' unless Rails.env.development?

      success = system('yarn swagger:validate doc/api/openapi/openapi_v2.yaml')
      abort('Validation of swagger document failed') unless success
    end

    task :generate do
      raise 'This task can only be run in the development environment' unless Rails.env.development?

      ENV['store'] = 'tmp/openapi.json'
      Rake::Task["oapi:fetch"].invoke(['openapi.json'])

      yaml_content = Gitlab::Json.parse(File.read('tmp/openapi_swagger_doc.json')).to_yaml

      File.write("doc/api/openapi/openapi_v2.yaml", yaml_content)
    end

    task generate_and_check: [:generate, :validate]
  end
end
