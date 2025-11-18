# frozen_string_literal: true

module Tasks
  module Ci
    class JobTokensTask
      ADMIN_PERMISSION = 'admin'
      READ_LABEL = 'Read'
      READ_AND_WRITE_LABEL = 'Read and write'
      POLICY_PATTERN = /^(read|admin)_(.+)/

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
        allowed_routes = find_allowed_routes
        routes_with_policies = allowed_routes.select { |route| has_policies?(route) }
        routes_without_policies = allowed_routes.reject { |route| has_policies?(route) }

        {
          categorized: build_categorized_documentation(routes_with_policies),
          unavailable: build_unavailable_table(routes_without_policies)
        }
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

      def table_for_routes(routes, include_policies: false)
        header = []
        header << 'Policies' if include_policies
        header += %w[Path Description]

        table = []
        table << markdown_row(header)
        table << markdown_row(header.map { |item| '-' * item.length })

        formatted_routes = routes.map do |route|
          row = []
          row << policies_for(route).join(', ') if include_policies
          row << "`#{route_path(route)}`"
          row << route.description
          markdown_row(row)
        end

        table += formatted_routes.uniq.sort
        table.join("\n")
      end

      def format_route(route)
        row = [
          route.description,
          "`#{route_path(route)}`",
          permission_names(route),
          scope_for(route)
        ]
        markdown_row(row)
      end

      def scope_for(route)
        policies = policies_for(route)
        return unless policies.present?

        permissions = policies.map do |policy|
          permission = extract_permission(policy)
          permission == ADMIN_PERMISSION ? READ_AND_WRITE_LABEL : READ_LABEL
        end.uniq

        permissions.join(', ')
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

      def route_path(route)
        [route.request_method, route.origin.delete_prefix('/api/:version')].join(' ')
      end

      def extract_permission(policy)
        POLICY_PATTERN.match(policy)&.captures&.first
      end

      def extract_category(policy)
        POLICY_PATTERN.match(policy)&.captures&.last
      end

      def primary_category_for_route(route)
        policies = policies_for(route)
        policies.first&.then { |policy| extract_category(policy)&.humanize }
      end

      def sort_routes_by_permission_level(routes)
        routes.sort_by do |route|
          permission_priority = has_admin_permission?(route) ? 1 : 0
          [permission_priority, route.description, route_path(route)]
        end
      end

      def has_admin_permission?(route)
        policies_for(route).any? do |policy|
          extract_permission(policy) == ADMIN_PERMISSION
        end
      end

      def format_unavailable_route(route)
        row = [route.description, "`#{route_path(route)}`"]
        markdown_row(row)
      end

      def markdown_row(row)
        "| #{row.join(' | ')} |"
      end

      def permission_names(route)
        policies = policies_for(route)
        return '' unless policies.present?

        policies.map { |policy| "`#{policy.upcase}`" }.join(', ')
      end

      def build_category_section(category, category_routes)
        section_title = "#{category} endpoints"
        "### #{section_title}\n\n#{generate_category_table(category_routes)}"
      end

      def generate_category_table(routes)
        header = ['Permission', 'API endpoint', 'Permission name', 'Scope']

        build_table(header) do
          sort_routes_by_permission_level(routes)
            .map { |route| format_route(route) }
            .uniq
        end
      end

      def build_table(header)
        table = []
        table << markdown_row(header)
        table << markdown_row(header.map { |item| '-' * item.length })
        table += yield
        table.join("\n")
      end

      def find_allowed_routes
        routes.select { |route| allowed_route?(route) }
      end

      def has_policies?(route)
        policies_for(route).present?
      end

      def build_categorized_documentation(routes)
        grouped_routes = group_routes_by_category_simple(routes)

        grouped_routes.map.with_index do |(category, category_routes), index|
          section = build_category_section(category, category_routes)
          section += "\n" unless index == grouped_routes.size - 1
          section
        end.join("\n")
      end

      def build_unavailable_table(routes)
        header = ['Permission', 'API endpoint']

        build_table(header) do
          routes
            .sort_by { |route| route_path(route) }
            .map { |route| format_unavailable_route(route) }
        end
      end

      def group_routes_by_category_simple(routes)
        categories = routes.filter_map { |route| primary_category_for_route(route) }.uniq.sort

        categories.filter_map do |category|
          category_routes = routes.select { |route| primary_category_for_route(route) == category }
          next if category_routes.empty?

          [category, category_routes]
        end.to_h
      end
    end
  end
end
