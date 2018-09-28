module QA
  module Factory
    module Resource
      class DeployKey < Factory::Base
        attr_accessor :title, :key

        product :fingerprint do |resource|
          Page::Project::Settings::Repository.act do
            expand_deploy_keys do |key|
              key_offset = key.key_titles.index do |title|
                title.text == resource.title
              end

              key.key_fingerprints[key_offset].text
            end
          end
        end

        dependency Factory::Resource::Project, as: :project do |project|
          project.name = 'project-to-deploy'
          project.description = 'project for adding deploy key test'
        end

        def fabricate!
          project.visit!

          Page::Menu::Side.act do
            click_repository_settings
          end

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
end
