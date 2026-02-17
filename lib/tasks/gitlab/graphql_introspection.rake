# frozen_string_literal: true

namespace :gitlab do
  introspection_output_dir = Rails.root.join('public/-/graphql')
  heading = '#' * 10

  # Some schema items are SaaS-only, and as we want to document them,
  # simulate SaaS when generating the GraphQL documentation.
  #
  # We would normally set ENV['GITLAB_SIMULATE_SAAS'] but `GitLab.com?`
  # is hard-coded to be `false` unless in development:
  # https://gitlab.com/gitlab-org/gitlab/-/blob/bc4cbb5d5a4b5e5a7e817f995e8d377978f246d3/lib/gitlab.rb#L58.
  #
  # `gitlab:graphql:generate_all_introspection_schemas` is run in our test pipelines so we need to
  # override `Gitlab.com?` to simulate SaaS

  # rubocop:disable Rake/TopLevelMethodDefinition -- required for this task
  task simulate_saas: :environment do
    next if Gitlab.com? # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- Necessary here.

    def Gitlab.com?
      true
    end

    at_exit do
      def Gitlab.com?
        false
      end
    end
  end

  task enable_introspection_feature_flags: :environment do
    def Feature.enabled?(*)
      true
    end
  end
  # rubocop:enable Rake/TopLevelMethodDefinition -- required for this task

  task generous_introspection_schema: :environment do
    GitlabSchema.validate_timeout 5.seconds
  end

  namespace :graphql do
    desc 'GitLab | GraphQL | Generate introspection schema for GraphiQL (production-safe)'
    task generate_introspection_schema: [:environment, :simulate_saas, :enable_introspection_feature_flags,
      :generous_introspection_schema] do
      FileUtils.mkdir_p(introspection_output_dir)

      begin
        context = { current_user: nil, introspection: true, remove_deprecated: Gitlab::Utils.to_boolean(false) }

        puts "Executing introspection query..."
        introspection_result = GitlabSchema.execute(
          CachedIntrospectionQuery.query_string,
          context: context
        )

        if introspection_result['errors']
          puts heading
          puts "#"
          introspection_result['errors'].each { |error| puts "# ERROR: #{error['message']}" }
          puts "#"
          puts heading

          abort
        end

        types_count = introspection_result.dig('data', '__schema', 'types')&.length || 0

        if types_count == 0
          puts heading
          puts "#"
          puts "# ERROR: Generated schema appears empty"
          puts "#"
          puts heading

          abort
        end

        json_file = File.join(introspection_output_dir, 'introspection_result.json')
        puts "Writing to: #{json_file}"
        formatted_json = "#{Gitlab::Json.pretty_generate(introspection_result)}\n"
        File.write(json_file, formatted_json)

        puts "GraphQL introspection schema generated successfully (#{types_count} types)"

      rescue StandardError => e
        puts heading
        puts "#"
        puts "# ERROR: #{e.message}"
        puts "#"
        puts heading

        abort
      end
    end

    desc 'GitLab | GraphQL | Generate introspection schema without deprecated fields'
    task generate_introspection_schema_no_deprecated: [:environment, :simulate_saas,
      :enable_introspection_feature_flags, :generous_introspection_schema] do
      FileUtils.mkdir_p(introspection_output_dir)

      begin
        context = { current_user: nil, introspection: true, remove_deprecated: Gitlab::Utils.to_boolean(true) }

        puts "Executing no-deprecated introspection query..."
        introspection_result = GitlabSchema.execute(
          CachedIntrospectionQuery.query_string_no_deprecated,
          context: context
        )

        if introspection_result['errors']
          puts heading
          puts "#"
          introspection_result['errors'].each { |error| puts "# ERROR: #{error['message']}" }
          puts "#"
          puts heading

          abort
        end

        types_count = introspection_result.dig('data', '__schema', 'types')&.length || 0

        if types_count == 0
          puts heading
          puts "#"
          puts "# ERROR: Generated schema appears empty"
          puts "#"
          puts heading

          abort
        end

        json_file = File.join(introspection_output_dir, 'introspection_result_no_deprecated.json')
        puts "Writing to: #{json_file}"
        formatted_json = "#{Gitlab::Json.pretty_generate(introspection_result)}\n"
        File.write(json_file, formatted_json)

        puts "GraphQL introspection schema generated successfully without deprecated fields (#{types_count} types)"

      rescue StandardError => e
        puts heading
        puts "#"
        puts "# ERROR: #{e.message}"
        puts "#"
        puts heading

        abort
      end
    end

    desc 'GitLab | GraphQL | Generate both introspection schemas'
    task generate_all_introspection_schemas: [
      :generate_introspection_schema,
      :generate_introspection_schema_no_deprecated
    ] do
      puts "✅ All GraphQL introspection schemas generated successfully"
    end

    desc 'GitLab | GraphQL | Clean introspection output directory'
    task :clean_introspection do
      FileUtils.rm_rf(Dir.glob(File.join(introspection_output_dir, '*'))) if Dir.exist?(introspection_output_dir)
    end

    desc 'GitLab | GraphQL | Check if introspection schema is up to date with source files'
    task check_introspection_sync: [:environment, :simulate_saas, :enable_introspection_feature_flags,
      :generous_introspection_schema] do
      introspection_schemas = [
        {
          name: 'full introspection schema',
          file_path: File.join(introspection_output_dir, 'introspection_result.json'),
          relative_path: 'public/-/graphql/introspection_result.json',
          query: CachedIntrospectionQuery.query_string,
          task_name: 'gitlab:graphql:generate_introspection_schema',
          remove_deprecated: false
        },
        {
          name: 'no-deprecated introspection schema',
          file_path: File.join(introspection_output_dir, 'introspection_result_no_deprecated.json'),
          relative_path: 'public/-/graphql/introspection_result_no_deprecated.json',
          query: CachedIntrospectionQuery.query_string_no_deprecated,
          task_name: 'gitlab:graphql:generate_introspection_schema_no_deprecated',
          remove_deprecated: true
        }
      ]

      out_of_date_schemas = []

      introspection_schemas.each do |schema|
        context = {
          current_user: nil,
          introspection: true,
          remove_deprecated: Gitlab::Utils.to_boolean(schema[:remove_deprecated])
        }
        current_introspection = GitlabSchema.execute(schema[:query], context: context)

        if current_introspection['errors']
          puts heading
          puts '#'
          puts "# ERROR generating current #{schema[:name]}:"
          current_introspection['errors'].each { |error| puts "# #{error['message']}" }
          puts '#'
          puts heading

          abort
        end

        current_schema_json = "#{Gitlab::Json.pretty_generate(current_introspection)}\n"

        # Check if existing schema file matches
        if File.exist?(schema[:file_path])
          existing_schema_json = File.read(schema[:file_path])

          out_of_date_schemas << schema unless current_schema_json == existing_schema_json
        else
          out_of_date_schemas << schema
        end

      rescue StandardError => e
        puts heading
        puts '#'
        puts "# ERROR generating current #{schema[:name]}: #{e.message}"
        puts '#'
        puts heading

        abort
      end

      if out_of_date_schemas.empty?
        puts "✅ All GraphQL introspection schemas are up to date"
      else
        puts heading
        puts '#'
        puts "# 🚫 One or more GraphQL Introspection Schemas need to be updated!"
        puts "#"
        out_of_date_schemas.each { |s| puts s[:relative_path] }
        puts "#"
        puts "#  Please regenerate the introspection schema by running:"
        puts "# bundle exec rake gitlab:graphql:generate_all_introspection_schemas"
        puts "#"
        puts "#  Add the newly generated file(s)"
        puts "#"
        puts heading

        abort
      end
    end
  end
end
