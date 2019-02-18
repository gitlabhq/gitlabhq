module QA
  module Page
    module Project
      module Import
        class Github < Page::Base
          include Page::Component::Select2

          view 'app/views/import/github/new.html.haml' do
            element :personal_access_token_field, 'text_field_tag :personal_access_token' # rubocop:disable QA/ElementWithPattern
            element :list_repos_button, "submit_tag _('List your GitHub repositories')" # rubocop:disable QA/ElementWithPattern
          end

          view 'app/assets/javascripts/import_projects/components/provider_repo_table_row.vue' do
            element :project_import_row
            element :project_namespace_select
            element :project_path_field
            element :import_button
          end

          def add_personal_access_token(personal_access_token)
            fill_in 'personal_access_token', with: personal_access_token
          end

          def list_repos
            click_button 'List your GitHub repositories'
          end

          def import!(full_path, name)
            choose_test_namespace(full_path)
            set_path(full_path, name)
            import_project(full_path)
          end

          private

          def within_repo_path(full_path)
            page.within(%Q(tr[data-qa-repo-path="#{full_path}"])) do
              yield
            end
          end

          def choose_test_namespace(full_path)
            within_repo_path(full_path) do
              click_element :project_namespace_select
            end

            select_item(Runtime::Namespace.path)
          end

          def set_path(full_path, name)
            within_repo_path(full_path) do
              fill_in 'path', with: name
            end
          end

          def import_project(full_path)
            within_repo_path(full_path) do
              click_button 'Import'
            end
          end
        end
      end
    end
  end
end
