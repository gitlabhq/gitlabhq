# frozen_string_literal: true

namespace :gitlab do
  namespace :openapi do
    namespace :v3 do
      task :validate do
        raise 'This task can only be run in the development environment' unless Rails.env.development?

        success = system('yarn swagger:validate doc/api/openapi/openapi_v3.yaml')
        abort('Validation of swagger document failed') unless success
      end

      desc 'GitLab | OpenAPI | Validate curated API tag content'
      task validate_tag_docs: :environment do
        require_relative 'validate_tag_docs_task'

        Tasks::Gitlab::Openapi::ValidateTagDocsTask.run
      end

      task generate: :environment do
        unless Rails.env.development? || Rails.env.test?
          raise 'This task can only be run in the development or test environment'
        end

        require_relative 'v3_document'

        # Force deterministic output unless the caller explicitly opts in for THIS task
        ENV['GITLAB_SIMULATE_SAAS'] = ENV['OPENAPI_SIMULATE_SAAS'].presence || 'false'
        puts "Generating OpenAPI v3 docs with GITLAB_SIMULATE_SAAS=#{ENV['GITLAB_SIMULATE_SAAS']} " \
          "(override with OPENAPI_SIMULATE_SAAS=true|false)"

        File.write("doc/api/openapi/openapi_v3.yaml", Tasks::Gitlab::Openapi::V3Document.render)
      end

      task generate_and_validate: [:generate, :validate]

      desc 'GitLab | OpenAPI | Check if OpenAPI v3 doc is up to date'
      task check_docs: :environment do
        require_relative 'v3_document'

        # Force deterministic output unless the caller explicitly opts in for THIS task
        ENV['GITLAB_SIMULATE_SAAS'] = ENV['OPENAPI_SIMULATE_SAAS'].presence || 'false'
        puts "Checking OpenAPI v3 docs with GITLAB_SIMULATE_SAAS=#{ENV['GITLAB_SIMULATE_SAAS']} " \
          "(override with OPENAPI_SIMULATE_SAAS=true|false)"

        generated_document = Tasks::Gitlab::Openapi::V3Document.render

        current_doc = Digest::SHA512.hexdigest(File.read("doc/api/openapi/openapi_v3.yaml"))
        generated_doc = Digest::SHA512.hexdigest(generated_document)

        if current_doc == generated_doc
          puts "OpenAPI v3 documentation is up to date"
        else
          heading = '#' * 10
          puts heading
          puts '#'
          puts '# OpenAPI documentation is outdated! Please update it by running `bin/rake gitlab:openapi:v3:generate`.'
          puts '#'
          puts heading

          if ENV["OPENAPI_CHECK_DEBUG"] == "true"
            File.write("doc/api/openapi/openapi_v3.yaml.generated", generated_document)
            sh "diff -u doc/api/openapi/openapi_v3.yaml doc/api/openapi/openapi_v3.yaml.generated"
          end

          abort
        end
      end
    end
  end
end
