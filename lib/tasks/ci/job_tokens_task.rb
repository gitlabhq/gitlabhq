# frozen_string_literal: true

module Tasks
  module Ci
    class JobTokensTask
      def initialize
        @routes = API::API.endpoints.flat_map(&:routes)
        @doc_path = Rails.root.join('doc/ci/jobs/fine_grained_permissions.md')
        @template_path = Rails.root.join('tooling/ci/job_tokens/docs/templates/fine_grained_permissions.md.erb')
      end

      def check_policies_completeness
        allowed_routes_without_policies = find_allowed_routes_without_policies
        if allowed_routes_without_policies.empty?
          puts 'All allowed endpoints for CI/CD job tokens have policies defined.'
        else
          puts '##########'
          puts '#'
          puts '# The following endpoints allowed for CI/CD job tokens should define job token policies:'
          puts '#'
          puts table_for_routes(allowed_routes_without_policies)
          puts '#'
          puts '##########'

          abort
        end
      end

      def check_policies_correctness
        routes_with_invalid_policies = find_routes_with_invalid_policies
        if routes_with_invalid_policies.empty?
          puts 'All defined CI/CD job token policies are valid.'
        else
          puts '##########'
          puts '#'
          puts '# The following endpoints have invalid CI/CD job token policies:'
          puts '#'
          puts table_for_routes(routes_with_invalid_policies, include_policies: true)
          puts '#'
          puts '##########'

          abort
        end
      end

      def check_docs
        doc = File.read(doc_path)

        template = ERB.new(File.read(template_path))
        if doc == template.result(binding)
          puts 'CI/CD job token allowed endpoints documentation is up to date.'
        else
          puts '##########'
          puts '#'
          puts '# CI/CD job token allowed endpoints documentation is outdated! Please update it by running ' \
            '`bundle exec rake ci:job_tokens:compile_docs`.'
          puts '#'
          puts '##########'

          abort
        end
      end

      def compile_docs
        template = ERB.new(File.read(template_path))
        File.write(doc_path, template.result(binding))

        puts 'CI/CD job token allowed endpoints documentation compiled.'
      end

      def allowed_endpoints
        routes_for_table = routes.select { |route| allowed_route?(route) }
        table_for_routes(routes_for_table, user_docs: true)
      end

      private

      attr_reader :routes, :doc_path, :template_path

      def find_allowed_routes_without_policies
        routes.select { |route| allowed_route?(route) && policies_for(route).empty? && !skip_route?(route) }
      end

      def find_routes_with_invalid_policies
        routes.select { |route| (policies_for(route) - valid_policies).present? }
      end

      def valid_policies
        @valid_policies ||= ::Ci::JobToken::Policies::POLICIES
      end

      def table_for_routes(routes, include_policies: false, user_docs: false)
        header  = []
        header << 'Policies' if include_policies

        if user_docs
          header << 'Permissions'
          header << 'Permission Names'
        end

        header += %w[Path Description]

        table  = []
        table << markdown_row(header)
        table << markdown_row(header.map { |item| '-' * item.length })

        formatted_routes = routes.map { |route| format_route(route, include_policies, user_docs) }
        table += formatted_routes.uniq.sort
        table.join("\n")
      end

      def format_route(route, include_policies, user_docs)
        row  = []
        row << policies_for(route).join(', ') if include_policies

        if user_docs
          row << resource_and_permissions_for(route)
          row << permission_names(route)
        end

        row << [
          "`#{route_path(route)}`",
          route.description
        ]

        markdown_row(row)
      end

      def markdown_row(row)
        "| #{row.join(' | ')} |"
      end

      def resource_and_permissions_for(route)
        policies = policies_for(route)
        return 'None' unless policies.present?

        policies.map do |policy|
          _, permission, category = policy.match(/^(read|admin)_(.+)/).to_a
          next policy unless permission && category

          permission = 'read_and_write' if permission == 'admin'
          "#{category.humanize}: #{permission.humanize}"
        end.join(', ')
      end

      def permission_names(route)
        policies = policies_for(route)
        return unless policies.present?

        policies.map { |policy| "`#{policy.upcase}`" }.join(', ')
      end

      def route_path(route)
        [route.request_method, route.origin.delete_prefix('/api/:version')].join(' ')
      end

      def allowed_route?(route)
        route.settings.dig(:authentication, :job_token_allowed)
      end

      def skip_route?(route)
        route.settings.dig(:authorization, :skip_job_token_policies)
      end

      def policies_for(route)
        Array(route.settings.dig(:authorization, :job_token_policies))
      end
    end
  end
end
