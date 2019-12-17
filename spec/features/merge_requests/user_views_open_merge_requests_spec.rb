# frozen_string_literal: true

require 'spec_helper'

describe 'User views open merge requests' do
  set(:user) { create(:user) }

  shared_examples_for 'shows merge requests' do
    it 'shows merge requests' do
      expect(page).to have_content(project.name).and have_content(merge_request.source_project.name)
    end
  end

  context 'when project is public' do
    set(:project) { create(:project, :public, :repository) }

    context 'when not signed in' do
      context "when the target branch is the project's default branch" do
        let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
        let!(:closed_merge_request) { create(:closed_merge_request, source_project: project, target_project: project) }

        before do
          visit(project_merge_requests_path(project))
        end

        include_examples 'shows merge requests'

        it 'shows open merge requests' do
          expect(page).to have_content(merge_request.title).and have_no_content(closed_merge_request.title)
        end

        it 'does not show target branch name' do
          expect(page).to have_content(merge_request.title)
          expect(find('.issuable-info')).not_to have_content(project.default_branch)
        end
      end

      context "when the target branch is different from the project's default branch" do
        let!(:merge_request) do
          create(:merge_request,
            source_project: project,
            target_project: project,
            source_branch: 'fix',
            target_branch: 'feature_conflict')
        end

        before do
          visit(project_merge_requests_path(project))
        end

        it 'shows target branch name' do
          expect(page).to have_content(merge_request.target_branch)
        end
      end

      context 'when a merge request has pipelines' do
        let!(:build) { create :ci_build, pipeline: pipeline }

        let(:merge_request) do
          create(:merge_request_with_diffs,
          source_project: project,
          target_project: project,
          source_branch: 'merge-test')
        end

        let(:pipeline) do
          create(:ci_pipeline,
            project: project,
            sha: merge_request.diff_head_sha,
            ref: merge_request.source_branch,
            head_pipeline_of: merge_request)
        end

        before do
          project.enable_ci

          visit(project_merge_requests_path(project))
        end

        it 'shows pipeline status' do
          page.within('.mr-list') do
            expect(page).to have_link('Pipeline: pending')
          end
        end
      end
    end

    context 'when signed in' do
      let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

      before do
        project.add_developer(user)
        sign_in(user)

        visit(project_merge_requests_path(project))
      end

      include_examples 'shows merge requests'

      it 'shows the new merge request button' do
        expect(page).to have_link('New merge request')
      end

      context 'when the project is archived' do
        let(:project) { create(:project, :public, :repository, :archived) }

        it 'hides the new merge request button' do
          expect(page).not_to have_link('New merge request')
        end
      end
    end
  end

  context 'when project is internal' do
    let!(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

    set(:project) { create(:project, :internal, :repository) }

    context 'when signed in' do
      before do
        project.add_developer(user)
        sign_in(user)

        visit(project_merge_requests_path(project))
      end

      include_examples 'shows merge requests'
    end
  end
end
