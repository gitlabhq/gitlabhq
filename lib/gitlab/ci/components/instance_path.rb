# frozen_string_literal: true

module Gitlab
  module Ci
    module Components
      class InstancePath
        include Gitlab::Utils::StrongMemoize

        LATEST_VERSION_KEYWORD = '~latest'
        TEMPLATES_DIR = 'templates'

        def self.match?(address)
          address.include?('@') && address.start_with?(Settings.gitlab_ci['component_fqdn'])
        end

        attr_reader :host

        def initialize(address:, content_filename:)
          @full_path, @version = address.to_s.split('@', 2)
          @content_filename = content_filename
          @host = Settings.gitlab_ci['component_fqdn']
        end

        def fetch_content!(current_user:)
          return unless project
          return unless sha

          raise Gitlab::Access::AccessDeniedError unless Ability.allowed?(current_user, :download_code, project)

          templates_dir_path_content || content(sha, custom_dir_template_file_path)
        end

        def project
          find_project_by_component_path(instance_path)
        end
        strong_memoize_attr :project

        def sha
          return unless project
          return latest_version_sha if version == LATEST_VERSION_KEYWORD

          project.commit(version)&.id
        end
        strong_memoize_attr :sha

        def project_file_path
          return unless project

          custom_dir_template_file_path
        end

        private

        attr_reader :version, :path

        def instance_path
          @full_path.delete_prefix(host)
        end

        def component_path
          instance_path.delete_prefix(project.full_path)
        end
        strong_memoize_attr :component_path

        # Given a path like "my-org/sub-group/the-project/path/to/component"
        # find the project "my-org/sub-group/the-project" by looking at all possible paths.
        def find_project_by_component_path(path)
          possible_paths = [path]

          while index = path.rindex('/') # find index of last `/` in a path
            possible_paths << (path = path[0..index - 1])
          end

          # remove shortest path as it is group
          possible_paths.pop

          ::Project.where_full_path_in(possible_paths).take # rubocop: disable CodeReuse/ActiveRecord
        end

        def latest_version_sha
          project.releases.latest&.sha
        end

        def custom_dir_template_file_path
          File.join(component_path, @content_filename).delete_prefix('/')
        end

        def templates_dir_file_path
          File.join(TEMPLATES_DIR, "#{component_path}.yml")
        end

        # Given a path like "my-org/sub-group/the-project/templates/component"
        # returns "templates/component/template.yml"
        def templates_dir_template_file_path
          File.join(TEMPLATES_DIR, component_path, @content_filename)
        end

        def templates_dir_exists?
          project.repository.tree.trees.map(&:name).include?(TEMPLATES_DIR)
        end

        def templates_dir_path_content
          return unless templates_dir_exists?

          content(sha, templates_dir_file_path) || content(sha, templates_dir_template_file_path)
        end

        def content(sha, path)
          project.repository.blob_data_at(sha, path)
        end
      end
    end
  end
end
