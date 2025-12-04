# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'View on environment', :js, feature_category: :groups_and_projects do
  let(:branch_name) { 'feature' }
  let(:file_path) { 'files/ruby/feature.rb' }
  let(:project) { create(:project, :repository) }
  let(:user) { project.creator }

  before do
    project.add_maintainer(user)
  end

  context 'when the branch has a route map' do
    let(:route_map) do
      <<-MAP.strip_heredoc
      - source: /files/(.*)\\..*/
        public: '\\1'
      MAP
    end

    before do
      Files::CreateService.new(
        project,
        user,
        start_branch: branch_name,
        branch_name: branch_name,
        commit_message: 'Add .gitlab/route-map.yml',
        file_path: '.gitlab/route-map.yml',
        file_content: route_map
      ).execute

      # Update the file so that we still have a commit that will have a file on the environment
      Files::UpdateService.new(
        project,
        user,
        start_branch: branch_name,
        branch_name: branch_name,
        commit_message: 'Update feature',
        file_path: file_path,
        file_content: '# Noop'
      ).execute
    end

    context 'and an active deployment' do
      let(:sha) { project.commit(branch_name).sha }
      let(:environment) { create(:environment, project: project, name: 'review/feature', external_url: 'http://feature.review.example.com') }
      let!(:deployment) { create(:deployment, :success, environment: environment, ref: branch_name, sha: sha) }

      context 'with legacy diffs' do
        before do
          stub_feature_flags(rapid_diffs_on_compare_show: false)
          sign_in(user)
          visit page_path
          wait_for_requests
        end

        where(:page_path) do
          [
            lazy { project_compare_path(project, from: 'master', to: branch_name) },
            lazy { project_commit_path(project, sha) }
          ]
        end

        with_them do
          it 'has a "View on env" button' do
            expect(page).to have_link('View on feature.review.example.com', href: 'http://feature.review.example.com/ruby/feature')
          end
        end
      end

      context 'with rapid diffs' do
        before do
          stub_feature_flags(rapid_diffs_on_compare_show: true)
        end

        context 'when visiting a comparison for the branch' do
          before do
            sign_in(user)

            visit project_compare_path(project, from: 'master', to: branch_name)

            wait_for_requests
          end

          it 'has a "View on env" button in the file header menu' do
            diff_file = all_by_testid('rd-diff-file').find do |file|
              file.has_text?(file_path)
            end
            diff_file.find('button:has([data-testid="ellipsis_v-icon"])').click

            expect(page).to have_link(
              'View on feature.review.example.com',
              href: 'http://feature.review.example.com/ruby/feature'
            )
          end
        end

        context 'when visiting the commit' do
          before do
            sign_in(user)

            visit project_commit_path(project, sha, rapid_diffs: true)

            wait_for_requests
          end

          it 'has a "View on env" button in the file header menu' do
            first_file = find_by_testid('rd-diff-file')
            first_file.find('button:has([data-testid="ellipsis_v-icon"])').click

            expect(page).to have_link(
              'View on feature.review.example.com',
              href: 'http://feature.review.example.com/ruby/feature'
            )
          end

          it 'opens the environment URL in a new tab' do
            first_file = find_by_testid('rd-diff-file')
            first_file.find('button:has([data-testid="ellipsis_v-icon"])').click

            link = page.find_link('View on feature.review.example.com')
            expect(link[:target]).to eq('_blank')
            expect(link[:rel]).to include('noopener')
          end
        end
      end

      context 'when visiting a blob on the branch' do
        before do
          sign_in(user)

          visit project_blob_path(project, File.join(branch_name, file_path))

          wait_for_requests
        end

        it 'has a "View on env" button' do
          click_button 'File actions'
          expect(page).to have_link('View on feature.review.example.com', href: 'http://feature.review.example.com/ruby/feature')
        end
      end

      context 'when visiting a blob on the commit' do
        before do
          sign_in(user)

          visit project_blob_path(project, File.join(sha, file_path))

          wait_for_requests
        end

        it 'has a "View on env" button' do
          click_button 'File actions'
          expect(page).to have_link('View on feature.review.example.com', href: 'http://feature.review.example.com/ruby/feature')
        end
      end
    end
  end
end
