# frozen_string_literal: true

module QA
  module Resource
    class DeployKey < Base
      attr_accessor :title, :key

      attribute :md5_fingerprint do
        Page::Project::Settings::Repository.perform do |setting|
          setting.expand_deploy_keys do |key|
            key.find_md5_fingerprint(title)
          end
        end
      end

      attribute :project do
        Project.fabricate! do |resource|
          resource.name = 'project-to-deploy'
          resource.description = 'project for adding deploy key test'
        end
      end

      def fabricate!
        project.visit!

        Page::Project::Menu.perform(&:go_to_repository_settings)

        Page::Project::Settings::Repository.perform do |setting|
          setting.expand_deploy_keys do |page|
            page.fill_key_title(title)
            page.fill_key_value(key)

            page.add_key
          end
        end
      end
    end
  end
end
