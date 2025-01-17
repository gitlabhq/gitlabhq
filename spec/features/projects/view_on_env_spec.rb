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

      stub_feature_flags(blob_overflow_menu: false)
    end

    context 'and an active deployment' do
      let(:sha) { project.commit(branch_name).sha }
      let(:environment) { create(:environment, project: project, name: 'review/feature', external_url: 'http://feature.review.example.com') }
      let!(:deployment) { create(:deployment, :success, environment: environment, ref: branch_name, sha: sha) }

      context 'when visiting a comparison for the branch' do
        before do
          sign_in(user)

          visit project_compare_path(project, from: 'master', to: branch_name)

          wait_for_requests
        end

        it 'has a "View on env" button' do
          expect(page).to have_link('View on feature.review.example.com', href: 'http://feature.review.example.com/ruby/feature')
        end
      end

      context 'when visiting a comparison for the commit' do
        before do
          sign_in(user)

          visit project_compare_path(project, from: 'master', to: sha)

          wait_for_requests
        end

        it 'has a "View on env" button' do
          expect(page).to have_link('View on feature.review.example.com', href: 'http://feature.review.example.com/ruby/feature')
        end
      end

      context 'when visiting a blob on the branch' do
        before do
          sign_in(user)

          visit project_blob_path(project, File.join(branch_name, file_path))

          wait_for_requests
        end

        it 'has a "View on env" button' do
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
          expect(page).to have_link('View on feature.review.example.com', href: 'http://feature.review.example.com/ruby/feature')
        end
      end

      context 'when visiting the commit' do
        before do
          sign_in(user)

          visit project_commit_path(project, sha)

          wait_for_requests
        end

        it 'has a "View on env" button' do
          expect(page).to have_link('View on feature.review.example.com', href: 'http://feature.review.example.com/ruby/feature')
        end
      end
    end
  end
end
