# frozen_string_literal: true

module QA
  module Page
    module Project
      module WorkItem
        class New < Page::Base
          include Page::Component::WorkItem::Widgets

          view 'app/assets/javascripts/work_items/components/create_work_item.vue' do
            element 'create-button'
            element 'work-item-types-select'
          end

          view 'app/assets/javascripts/vue_shared/components/markdown/markdown_editor.vue' do
            element 'markdown-editor-form-field'
          end

          view 'app/assets/javascripts/work_items/components/work_item_milestone.vue' do
            element 'work-item-milestone'
          end

          view 'app/assets/javascripts/work_items/components/work_item_title.vue' do
            element 'work-item-title-input'
          end

          view 'app/assets/javascripts/work_items/components/work_item_description_template_listbox.vue' do
            element 'template-dropdown'
            element 'template-item'
          end

          def select_type(type)
            click_element('work-item-types-select')
            find_element('work-item-types-select').select(type).click
          end

          def fill_title(title)
            fill_element('work-item-title-input', title)
          end

          def fill_description(description)
            fill_element('markdown-editor-form-field', description)
          end

          def choose_milestone(milestone)
            within_element('work-item-milestone') do
              click_element('edit-button')
              wait_until(reload: false) do
                has_text?(milestone.title, wait: 0)
              end
              find_element("listbox-item-gid://gitlab/Milestone/#{milestone.id}").click
            end
          end

          def choose_template(template_name)
            click_element('template-dropdown')
            within_element('template-dropdown') do
              find_element('template-item', text: template_name).click
            end
          end

          def create_new_work_item
            click_element('create-button', Page::Project::WorkItem::Show)
          end
        end
      end
    end
  end
end

QA::Page::Project::WorkItem::New.prepend_mod_with('Page::Project::WorkItem::New', namespace: QA)
