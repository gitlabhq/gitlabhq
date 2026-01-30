# frozen_string_literal: true

# See `spec/frontend/path_helpers/*_spec.js` for specs
module Gitlab
  module JsRoutes
    class << self
      PATH_HELPERS_PATH = 'app/assets/javascripts/lib/utils/path_helpers'
      EE_PATH_HELPERS_PATH = 'ee/app/assets/javascripts/lib/utils/path_helpers'

      def generate!
        original_route_source_locations = ActionDispatch::Routing::Mapper.route_source_locations

        begin
          unless original_route_source_locations
            # When route source locations are disabled (building in production and tests)
            # we temporarily enable them so we can use route.source_location to determine
            # how to split up the JavaScript path helpers into multiple files.
            ActionDispatch::Routing::Mapper.route_source_locations = true

            # Reload routes to capture source locations
            Rails.application.reload_routes!
          end

          ee_route_pairs, ce_route_pairs = group_route_pairs_by_ee_or_ce

          generate_path_helpers!(group_route_pairs_by_namespace(ee_route_pairs), EE_PATH_HELPERS_PATH)
          generate_path_helpers!(group_route_pairs_by_namespace(ce_route_pairs), PATH_HELPERS_PATH)

          js_routes_core = <<~JS
          #{::JsRoutes.generate}
          export { __jsr };
          JS
          core_file_path = Rails.root.join(PATH_HELPERS_PATH, 'core.js')

          write_file_if_changed(core_file_path, js_routes_core)

          utils = javascript_utils
          utils_file_path = Rails.root.join(PATH_HELPERS_PATH, 'utils.js')

          write_file_if_changed(utils_file_path, utils)
        ensure
          # Restore original setting
          ActionDispatch::Routing::Mapper.route_source_locations = original_route_source_locations
        end
      end

      private

      def route_source_location(route)
        return unless route.respond_to?(:source_location)
        return if route.source_location.nil?

        route.source_location
      end

      def write_file_if_changed(file_path, output)
        # Create the directory if it doesn't exist
        FileUtils.mkdir_p(File.dirname(file_path))

        # We don't need to rewrite file if it already exist and have same content.
        # It helps webpack understand that file wasn't changed.
        return if File.exist?(file_path) && File.read(file_path) == output

        File.write(file_path, output)
      end

      # Group route pairs by their namespace (source location)
      def group_route_pairs_by_namespace(route_pairs)
        route_pairs.group_by do |global_route, _|
          source_location = route_source_location(global_route)
          if source_location.nil?
            'miscellaneous'
          else
            # Extract filename from source location (e.g., "config/routes/projects.rb:15" -> "projects")
            File.basename(source_location.split(':').first, '.rb')
          end
        end
      end

      # Group routes by EE or CE
      def group_route_pairs_by_ee_or_ce
        routes = Rails.application.routes.routes.to_a.index_by(&:name)

        route_name_pairs = ::Routing::OrganizationsHelper::MappedHelpers.find_route_pairs

        route_pairs = route_name_pairs
          .filter_map do |global_route_name, organization_route_name|
            next if global_route_name.nil?

            global_route = routes[global_route_name]
            organization_route = routes[organization_route_name]

            [global_route, organization_route]
          end

        route_pairs.partition do |global_route, _|
          source_location = route_source_location(global_route)
          next false if source_location.nil?

          source_location.include?('ee/config')
        end
      end

      def generate_path_helpers!(grouped_route_pairs, base_path)
        grouped_route_pairs.each do |namespace, route_pairs|
          path_helpers = route_pairs.map do |global_route, organization_route|
            generate_path_helper(global_route, organization_route)
          end.join("\n")

          utils_import = if path_helpers.include?('splitProjectFullPath')
                           <<~JS
                            import { hasOrganizationScopedPaths, splitProjectFullPath } from '~/lib/utils/path_helpers/utils';
                           JS
                         else
                           <<~JS
                            import { hasOrganizationScopedPaths } from '~/lib/utils/path_helpers/utils';
                           JS
                         end

          output = <<~JS
            import { __jsr } from '~/lib/utils/path_helpers/core';
            #{utils_import}

            #{path_helpers}
          JS
          file_path = Rails.root.join(base_path, "#{namespace}.js")

          write_file_if_changed(file_path, output)
        end
      end

      def generate_path_helper(global_route, organization_route)
        # To support short hand project helpers defined in
        # https://gitlab.com/gitlab-org/gitlab/-/blob/4202e37329fb343ae674db79593ce04427ebab6b/config/routes.rb#L368
        if global_route.name.include?('namespace_project')
          return generate_project_path_helper(global_route, organization_route)
        end

        generate_standard_path_helper(global_route, organization_route)
      end

      # To support short hand project helpers defined in
      # https://gitlab.com/gitlab-org/gitlab/-/blob/4202e37329fb343ae674db79593ce04427ebab6b/config/routes.rb#L368
      def generate_project_path_helper(global_route, organization_route)
        global_jsdoc, global_path_helper_name, global_path_helper = generate_global_path_helper(global_route)
        organization_path_helper_name, organization_path_helper = generate_organization_path_helper(
          organization_route
        )

        private_global_path_helper_name = private_path_helper_name(global_path_helper_name)
        private_organization_path_helper_name = private_path_helper_name(organization_path_helper_name)

        # Adjust arguments in JSDoc to show projectPath as the argument
        jsdoc = global_jsdoc
          .sub(%r{\*namespace_id/:(?:project_)?id}, ':project_full_path')
          .sub(
            / \* @param {any} namespaceId\n \* @param {any} (?:project)?[Ii]d/,
            ' * @param {string} projectFullPath'
          )

        project_path_helper_name =
          "#{global_route.name.sub('namespace_project', 'project')}_path".camelize(:lower)

        <<~JS
            #{jsdoc}export const #{project_path_helper_name} = /*#__PURE__*/ (projectFullPath, ...args) => {
              const #{private_organization_path_helper_name} = #{organization_path_helper};
              const #{private_global_path_helper_name} = #{global_path_helper};

              const { namespacePath, projectPath } = splitProjectFullPath(projectFullPath);

              if (hasOrganizationScopedPaths()) {
                return #{private_organization_path_helper_name}(gon?.current_organization.path, namespacePath, projectPath, ...args);
              }

              return #{private_global_path_helper_name}(namespacePath, projectPath, ...args);
            };
        JS
      end

      def generate_standard_path_helper(global_route, organization_route)
        global_jsdoc, global_path_helper_name, global_path_helper = generate_global_path_helper(global_route)
        organization_path_helper_name, organization_path_helper = generate_organization_path_helper(
          organization_route
        )

        private_global_path_helper_name = private_path_helper_name(global_path_helper_name)
        private_organization_path_helper_name = private_path_helper_name(organization_path_helper_name)

        <<~JS
          #{global_jsdoc}export const #{global_path_helper_name} = /*#__PURE__*/ (...args) => {
            const #{private_organization_path_helper_name} = #{organization_path_helper};
            const #{private_global_path_helper_name} = #{global_path_helper};

            if (hasOrganizationScopedPaths()) {
              return #{private_organization_path_helper_name}(gon?.current_organization.path, ...args);
            }

            return #{private_global_path_helper_name}(...args);
          };
        JS
      end

      # Generate path helper for global route
      def generate_global_path_helper(global_route)
        ::JsRoutes::Route.new(
          ::JsRoutes.configuration,
          global_route
        ).helpers[0]
      end

      # Generate path helper for scoped organization route
      def generate_organization_path_helper(organization_route)
        _, organization_path_helper_name, organization_path_helper = ::JsRoutes::Route.new(
          ::JsRoutes.configuration,
          organization_route
        ).helpers[0]

        [organization_path_helper_name, organization_path_helper]
      end

      # Prefix path helper name with underscore to mark as private
      def private_path_helper_name(path_helper_name)
        "_#{path_helper_name}"
      end

      def javascript_utils
        <<~JS
          // Check if the current organization has a scoped path.
          // Calls https://gitlab.com/gitlab-org/gitlab/-/blob/4202e37329fb343ae674db79593ce04427ebab6b/app/models/organizations/organization.rb#L127
          // Used to support automatic swapping of organization scoped routes similar to what we do in
          // https://gitlab.com/gitlab-org/gitlab/-/blob/4202e37329fb343ae674db79593ce04427ebab6b/app/helpers/routing/organizations_helper.rb#L92
          export const hasOrganizationScopedPaths = () =>
            gon?.current_organization?.has_scoped_paths ?? false;

          // The private `namespaceProject` helpers expect separate `namespacePath`
          // and `projectPath` arguments. Typically we only have `project.fullPath`
          // available on the frontend. This util splits `project.fullPath` into
          // separate arguments so they can be passed to the private `namespaceProject` helpers.
          export const splitProjectFullPath = (projectFullPath) => {
            if (!projectFullPath) {
              throw new Error('Route missing required keys: projectFullPath');
            }

            if (typeof projectFullPath !== 'string') {
              throw new Error('projectFullPath must be a string');
            }

            const splitProjectFullPath = projectFullPath.split("/");
            const namespacePath = splitProjectFullPath.slice(0, -1).join("/");
            const projectPath = splitProjectFullPath.at(-1);

            return { namespacePath, projectPath };
          };
        JS
      end
    end
  end
end
