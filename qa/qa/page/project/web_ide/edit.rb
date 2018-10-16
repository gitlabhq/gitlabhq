# frozen_string_literal: true

module QA
  module Page
    module Project
      module WebIDE
        class Edit < Page::Base
          include Page::Component::DropdownFilter

          view 'app/assets/javascripts/ide/components/ide_tree.vue' do
            element :new_file
          end

          view 'app/assets/javascripts/ide/components/ide_tree_list.vue' do
            element :file_list
          end

          view 'app/assets/javascripts/ide/components/new_dropdown/modal.vue' do
            element :full_file_path
            element :template_list
          end

          view 'app/assets/javascripts/ide/components/file_templates/bar.vue' do
            element :file_templates_bar
            element :file_template_dropdown
          end

          view 'app/assets/javascripts/ide/components/file_templates/dropdown.vue' do
            element :dropdown_filter_input
          end

          view 'app/assets/javascripts/ide/components/commit_sidebar/form.vue' do
            element :begin_commit_button
            element :commit_button
          end

          def has_file?(file_name)
            within_element(:file_list) do
              page.has_content? file_name
            end
          end

          def create_new_file_from_template(file_name, template)
            click_element :new_file
            within_element(:template_list) do
              begin
                click_on file_name
              rescue Capybara::ElementNotFound
                raise ElementNotFound, %Q(Couldn't find file template named "#{file_name}". Please confirm that it is a valid option.)
              end
            end

            wait(reload: false) do
              within_element(:file_templates_bar) do
                click_element :file_template_dropdown
                fill_element :dropdown_filter_input, template

                begin
                  click_on template
                rescue Capybara::ElementNotFound
                  raise ElementNotFound, %Q(Couldn't find template "#{template}" for #{file_name}. Please confirm that it exists in the list of templates.)
                end
              end
            end
          end

          def commit_changes
            click_element :begin_commit_button
            click_element :commit_button

            wait(reload: false) do
              page.has_content?('Your changes have been committed')
            end
          end
        end
      end
    end
  end
end
