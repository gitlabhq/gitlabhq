# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sandboxed Mermaid rendering', :js, feature_category: :markdown do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, :public, :repository, group: subgroup) }
  let_it_be(:description) do
    <<~MERMAID
    ```mermaid
    graph TD;
      A-->B;
      A-->C;
      B-->D;
      C-->D;
    ```
    MERMAID
  end

  let_it_be(:issue) { create(:issue, project: project, description: description) }

  let(:sandbox_path) { sandbox_mermaid_v12_path }

  let(:mermaid_frame_selector) do
    src_prefix = "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}#{sandbox_path}"
    "iframe[src^='#{src_prefix}'][sandbox='allow-scripts']"
  end

  context 'in an issue' do
    shared_examples 'renders flowchart layouts' do
      after do
        expect_page_to_have_no_console_errors
      end

      {
        'default' => '',
        'ELK' => "---\nconfig:\n  layout: elk\n---\n"
      }.each do |layout, configuration|
        context "with the #{layout} layout" do
          let_it_be(:diagram_issue) do
            create(:issue, project: project, description: <<~MERMAID)
              ```mermaid
              #{configuration}flowchart LR
                A[Start] --> B{Review}
                B -->|Yes| C[Done]
                B -->|No| A
              ```
            MERMAID
          end

          it 'renders nodes and edges inside the sandbox', :with_license, :aggregate_failures do
            visit project_issue_path(project, diagram_issue)

            page.within_frame(find(mermaid_frame_selector)) do
              within('#app > svg') do
                expect(page).to have_css('.node', count: 3)
                expect(page).to have_css('.flowchart-link', count: 3)

                expect(page).to have_css('.nodeLabel', exact_text: 'Start')
                expect(page).to have_css('.nodeLabel', exact_text: 'Review')
                expect(page).to have_css('.nodeLabel', exact_text: 'Done')
              end
            end
          end
        end
      end
    end

    it_behaves_like 'renders flowchart layouts'

    context 'when use_mermaid_v12 is disabled' do
      let(:sandbox_path) { sandbox_mermaid_v11_path }

      before do
        stub_feature_flags(use_mermaid_v12: false)
      end

      it_behaves_like 'renders flowchart layouts'
    end
  end

  context 'in a merge request' do
    let(:merge_request) { create(:merge_request_with_diffs, source_project: project, description: description) }

    it 'renders diffs and includes mermaid frame correctly' do
      visit(diffs_project_merge_request_path(project, merge_request))

      page.within('.tab-content') do
        expect(page).to have_selector('.diffs')
      end

      visit(project_merge_request_path(project, merge_request))

      page.within('.merge-request') do
        expect(page).to have_css(mermaid_frame_selector)
      end
    end
  end

  context 'in a project milestone' do
    let(:milestone) { create(:project_milestone, project: project, description: description) }

    it 'includes mermaid frame correctly' do
      visit(project_milestone_path(project, milestone))

      expect(page).to have_css(mermaid_frame_selector)
    end
  end

  context 'in a project home page' do
    let_it_be_with_refind(:project) { create(:project, :public, :repository, group: subgroup) }

    let!(:wiki) { create(:project_wiki, project: project) }
    let!(:wiki_page) { create(:wiki_page, wiki: wiki, title: 'home', content: description) }

    before do
      project.project_feature.update_attribute(:repository_access_level, ProjectFeature::DISABLED)
    end

    it 'includes mermaid frame correctly' do
      visit(project_path(project))

      page.within '.js-wiki-content' do
        expect(page).to have_css(mermaid_frame_selector)
      end
    end
  end

  context 'in a group milestone' do
    let(:group_milestone) { create(:group_milestone, description: description) }

    it 'includes mermaid frame correctly' do
      visit(group_milestone_path(group_milestone.group, group_milestone))

      expect(page).to have_css(mermaid_frame_selector)
    end
  end

  describe 'use_mermaid_v12 feature flag' do
    shared_examples 'uses the sandbox at' do |path_helper|
      let(:sandbox_path) { public_send(path_helper) }

      it "uses #{path_helper}" do
        visit project_issue_path(project, issue)

        expect(page).to have_css(mermaid_frame_selector)
      end
    end

    context 'when disabled' do
      before do
        stub_feature_flags(use_mermaid_v12: false)
      end

      it_behaves_like 'uses the sandbox at', :sandbox_mermaid_v11_path
    end

    context 'when enabled for the project' do
      before do
        stub_feature_flags(use_mermaid_v12: project)
      end

      it_behaves_like 'uses the sandbox at', :sandbox_mermaid_v12_path
    end

    context 'when enabled for the immediate group' do
      before do
        stub_feature_flags(use_mermaid_v12: subgroup)
      end

      it_behaves_like 'uses the sandbox at', :sandbox_mermaid_v12_path
    end

    context 'when enabled for an ancestor group' do
      before do
        stub_feature_flags(use_mermaid_v12: group)
      end

      it_behaves_like 'uses the sandbox at', :sandbox_mermaid_v12_path
    end
  end
end
