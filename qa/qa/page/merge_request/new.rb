# frozen_string_literal: true

module QA
  module Page
    module MergeRequest
      class New < Page::Issuable::New
        include QA::Page::Component::Dropdown

        view 'app/views/shared/issuable/_form.html.haml' do
          element 'issuable-create-button', required: true
        end

        view 'app/views/projects/merge_requests/creations/_new_compare.html.haml' do
          element 'compare-branches-button'
        end

        view 'app/assets/javascripts/merge_requests/components/compare_app.vue' do
          element 'compare-dropdown'
        end

        view 'app/views/projects/merge_requests/creations/_new_submit.html.haml' do
          element 'diffs-tab'
        end

        view 'app/assets/javascripts/diffs/components/diff_file_header.vue' do
          element 'file-name-content'
        end

        def has_secure_description?(scanner_name)
          scanner_url_name = scanner_name.downcase.tr('_', '-')
          "Configure #{scanner_name} in `.gitlab-ci.yml` using the GitLab managed template. You can " \
            "[add variable overrides](https://docs.gitlab.com/ee/user/application_security/#{scanner_url_name}/#customizing-the-#{scanner_url_name}-settings) " \
            "to customize #{scanner_name} settings."
        end

        def click_compare_branches_and_continue
          click_element('compare-branches-button')
        end

        def create_merge_request
          click_element('issuable-create-button', Page::MergeRequest::Show)
        end

        def click_diffs_tab
          click_element('diffs-tab')
        end

        def has_file?(file_name)
          has_element?('file-name-content', text: file_name)
        end

        def select_source_branch(branch)
          click_element('compare-dropdown', 'compare-side': 'source')
          search_and_select(branch)
        end
      end
    end
  end
end

QA::Page::MergeRequest::New.prepend_mod_with('Page::MergeRequest::New', namespace: QA)
