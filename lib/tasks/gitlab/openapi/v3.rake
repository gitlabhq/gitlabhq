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
        committed_document = File.read("doc/api/openapi/openapi_v3.yaml")

        milestone = /\A\d+\.\d+\z/

        # release-tools rewrites VERSION on stable branches at every release tag, so each
        # document's info.version is checked for shape only, never against the other's.
        # Located via the YAML node tree so indentation cannot affect it.
        # Checked on the committed document too: the exclusion below would hide a hand-edited value.
        info_version_line = ->(document, source) do
          info = YAML.parse(document).children&.first&.children&.each_slice(2)
                     &.find { |key, _| key.respond_to?(:value) && key.value == 'info' }&.last
          abort "#{source}: cannot find the info section" unless info

          key, value = info.children.each_slice(2).find { |k, _| k.value == 'version' }
          abort "#{source}: info.version is missing" unless key

          unless value.value.match?(milestone)
            abort "#{source}: info.version must be a MAJOR.MINOR milestone such as 19.3, found: #{value.value.inspect}"
          end

          key.start_line
        end

        committed_line = info_version_line.call(committed_document, 'committed')
        generated_line = info_version_line.call(generated_document, 'generated')

        without_info_version = ->(document, line) { document.lines.tap { |l| l.delete_at(line) }.join }

        current_doc = Digest::SHA512.hexdigest(without_info_version.call(committed_document, committed_line))
        generated_doc = Digest::SHA512.hexdigest(without_info_version.call(generated_document, generated_line))

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
            # Carry over the committed info.version so the excluded field cannot appear as a
            # difference here and send readers after the wrong cause.
            debug_lines = generated_document.lines
            debug_lines[generated_line] = committed_document.lines[committed_line]

            File.write("doc/api/openapi/openapi_v3.yaml.generated", debug_lines.join)
            sh "diff -u doc/api/openapi/openapi_v3.yaml doc/api/openapi/openapi_v3.yaml.generated"
          end

          abort
        end
      end
    end
  end
end
