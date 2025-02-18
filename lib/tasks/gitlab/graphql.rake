# frozen_string_literal: true

return if Rails.env.production?

namespace :gitlab do
  require 'graphql/rake_task'
  require_relative '../../../tooling/graphql/docs/renderer'

  OUTPUT_DIR = Rails.root.join("doc/api/graphql/reference")
  TEMP_SCHEMA_DIR = Rails.root.join('tmp/tests/graphql')
  TEMPLATES_DIR = 'tooling/graphql/docs/templates/'

  # Make all feature flags enabled so that all feature flag
  # controlled fields are considered visible and are output.
  # Also avoids pipeline failures in case developer
  # dumps schema with flags disabled locally before pushing
  task enable_feature_flags: :environment do
    def Feature.enabled?(*args)
      true
    end
  end

  task generous_gitlab_schema: :environment do
    GitlabSchema.validate_timeout 1.second
    puts "Validation timeout set to #{GitlabSchema.validate_timeout} second(s)"
  end

  # Defines tasks for dumping the GraphQL schema:
  # - gitlab:graphql:schema:dump
  # - gitlab:graphql:schema:idl
  # - gitlab:graphql:schema:json
  GraphQL::RakeTask.new(
    schema_name: 'GitlabSchema',
    dependencies: [:environment, :enable_feature_flags, :generous_gitlab_schema],
    directory: TEMP_SCHEMA_DIR,
    idl_outfile: "gitlab_schema.graphql",
    json_outfile: "gitlab_schema.json"
  )

  namespace :graphql do
    desc 'GitLab | GraphQL | Analyze queries'
    task analyze: [:environment, :enable_feature_flags] do |t, args|
      queries = if args.to_a.present?
                  args.to_a.flat_map { |path| Gitlab::Graphql::Queries.find(path) }
                else
                  Gitlab::Graphql::Queries.all
                end

      queries.each do |defn|
        $stdout.puts defn.file
        summary, errs = defn.validate(GitlabSchema)

        if summary == :client_query
          $stdout.puts " - client query"
        elsif errs.present?
          $stdout.puts Rainbow(" - invalid query").red
        else
          complexity = defn.complexity(GitlabSchema)
          color = case complexity
                  when 0..GitlabSchema::DEFAULT_MAX_COMPLEXITY
                    :green
                  when GitlabSchema::DEFAULT_MAX_COMPLEXITY..GitlabSchema::AUTHENTICATED_MAX_COMPLEXITY
                    :yellow
                  when GitlabSchema::AUTHENTICATED_MAX_COMPLEXITY..GitlabSchema::ADMIN_MAX_COMPLEXITY
                    :orange
                  else
                    :red
                  end

          $stdout.puts Rainbow(" - complexity: #{complexity}").color(color)
        end

        $stdout.puts ""
      end
    end

    desc 'GitLab | GraphQL | Validate queries'
    task validate: [:environment, :enable_feature_flags, :generous_gitlab_schema] do |t, args|
      queries = if args.to_a.present?
                  args.to_a.flat_map { |path| Gitlab::Graphql::Queries.find(path) }
                else
                  Gitlab::Graphql::Queries.all
                end

      failed = queries.flat_map do |defn|
        summary, errs = defn.validate(GitlabSchema)

        case summary
        when :client_query
          warn("SKIP  #{defn.file}: client query")
        else
          warn("#{Rainbow('OK').green}    #{defn.file}") if errs.empty?
          errs.each do |err|
            path_info = "(at #{err.path.join('.')})" if err.path

            warn(<<~MSG)
            #{Rainbow('ERROR').red} #{defn.file}: #{err.message} #{path_info}
            MSG
          end
        end

        errs.empty? ? [] : [defn.file]
      end

      if failed.present?
        format_output(
          "#{failed.count} GraphQL #{'query'.pluralize(failed.count)} out of #{queries.count} failed validation:",
          *failed.map do |name|
            known_failure = Gitlab::Graphql::Queries.known_failure?(name)
            "- #{name}" + (known_failure ? ' (known failure)' : '')
          end
        )
        abort unless failed.all? { |name| Gitlab::Graphql::Queries.known_failure?(name) }
      end
    end

    desc 'GitLab | GraphQL | Generate GraphQL docs'
    task compile_docs: [:environment, :enable_feature_flags] do
      renderer = Tooling::Graphql::Docs::Renderer.new(GitlabSchema, **render_options)

      renderer.write

      puts "Documentation compiled."
    end

    desc 'GitLab | GraphQL | Check if GraphQL docs are up to date'
    task check_docs: [:environment, :enable_feature_flags] do
      renderer = Tooling::Graphql::Docs::Renderer.new(GitlabSchema, **render_options)

      doc = File.read(Rails.root.join(OUTPUT_DIR, '_index.md'))

      if doc == renderer.contents
        puts "GraphQL documentation is up to date"
      else
        format_output('GraphQL documentation is outdated! Please update it by running `bundle exec rake gitlab:graphql:compile_docs`.')
        abort
      end
    end

    desc 'GitLab | GraphQL | Update GraphQL docs and schema'
    task update_all: [:compile_docs, 'schema:dump']
  end
end

def render_options
  {
    output_dir: OUTPUT_DIR,
    template: Rails.root.join(TEMPLATES_DIR, 'default.md.haml')
  }
end

def format_output(*strs)
  heading = '#' * 10
  puts heading
  puts '#'
  strs.each { |str| puts "# #{str}" }
  puts '#'
  puts heading
end
