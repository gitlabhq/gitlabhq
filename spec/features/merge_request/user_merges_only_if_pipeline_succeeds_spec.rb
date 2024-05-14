# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User merges only if pipeline succeeds', :js, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request_with_diffs) }
  let(:project)       { merge_request.target_project }

  before do
    project.add_maintainer(merge_request.author)
    sign_in(merge_request.author)
  end

  context 'project does not have CI enabled' do
    it 'allows MR to be merged' do
      visit project_merge_request_path(project, merge_request)

      wait_for_requests

      page.within('.mr-state-widget') do
        expect(page).to have_button 'Merge'
      end
    end

    context 'when an active pipeline running' do
      let!(:pipeline) do
        create(
          :ci_empty_pipeline,
          project: project,
          sha: merge_request.diff_head_sha,
          ref: merge_request.source_branch,
          status: :running,
          head_pipeline_of: merge_request
        )
      end

      it 'allows MR to be merged' do
        visit project_merge_request_path(project, merge_request)

        wait_for_requests

        page.within('.mr-state-widget') do
          expect(page).to have_button 'Set to auto-merge'
        end
      end
    end
  end

  context 'when project has CI enabled' do
    let!(:pipeline) do
      create(
        :ci_empty_pipeline,
        project: project,
        sha: merge_request.diff_head_sha,
        ref: merge_request.source_branch,
        status: status,
        head_pipeline_of: merge_request
      )
    end

    context 'when merge requests can only be merged if the pipeline succeeds' do
      before do
        project.update_attribute(:only_allow_merge_if_pipeline_succeeds, true)
      end

      context 'when CI failed' do
        let(:status) { :failed }

        it 'does not allow MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).not_to have_button('Merge', exact: true)

          click_button 'Expand merge checks'

          expect(page).to have_content('Pipeline must succeed.')
        end
      end

      context 'when CI canceled' do
        let(:status) { :canceled }

        it 'does not allow MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).not_to have_button('Merge', exact: true)

          click_button 'Expand merge checks'

          expect(page).to have_content('Pipeline must succeed.')
        end
      end

      context 'when CI succeeded' do
        let(:status) { :success }

        it 'allows MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).to have_button('Merge', exact: true)
        end
      end

      context 'when CI skipped' do
        let(:status) { :skipped }

        it 'does not allow MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).not_to have_button('Merge', exact: true)
        end
      end

      context 'when CI is running', :sidekiq_inline do
        let(:status) { :running }

        it 'does not allow to merge immediately' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).to have_button 'Set to auto-merge'
          expect(page).not_to have_button '.js-merge-moment'
        end

        context 'when auto-merge is set' do
          before do
            visit project_merge_request_path(project, merge_request)

            wait_for_requests

            click_button('Set to auto-merge')
            wait_for_requests
          end

          context 'when CI passes' do
            before do
              pipeline.set_status('success')
            end

            it 'the MR gets merged' do
              expect(page).to have_content("Pipeline ##{pipeline.id} passed")

              wait_for_requests

              expect(page).to have_content('Merged by')
            end
          end

          context 'when CI fails' do
            before do
              pipeline.set_status('failed')
            end

            it 'MR is blocked' do
              expect(page).to have_content("Pipeline ##{pipeline.id} failed")

              wait_for_requests

              page.within('.mr-state-widget') do
                expect(page).to have_content('Merge blocked')
              end
            end
          end

          context 'when CI is canceled' do
            before do
              pipeline.set_status('canceled')
            end

            it 'MR is blocked' do
              expect(page).to have_content("Pipeline ##{pipeline.id} canceled")

              wait_for_requests

              page.within('.mr-state-widget') do
                expect(page).to have_content('Merge blocked')
              end
            end
          end
        end
      end
    end

    context 'when merge requests can be merged when the build failed' do
      before do
        project.update_attribute(:only_allow_merge_if_pipeline_succeeds, false)
      end

      context 'when CI failed' do
        let(:status) { :failed }

        it 'allows MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          page.within('.mr-state-widget') do
            expect(page).to have_button 'Merge'
          end
        end
      end

      context 'when CI is running', :sidekiq_inline do
        let(:status) { :running }

        it 'allows MR to be merged immediately' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).to have_button 'Set to auto-merge'

          page.find('.js-merge-moment').click
          expect(page).to have_content 'Merge immediately'
        end

        context 'when auto-merge is set' do
          before do
            visit project_merge_request_path(project, merge_request)

            wait_for_requests

            click_button('Set to auto-merge')
            wait_for_requests
          end

          context 'when CI passes' do
            before do
              pipeline.set_status('success')
            end

            it 'the MR gets merged' do
              expect(page).to have_content("Pipeline ##{pipeline.id} passed")

              wait_for_requests

              expect(page).to have_content('Merged by')
            end
          end

          context 'when CI fails' do
            before do
              pipeline.set_status('failed')
            end

            it 'MR remains set to auto-merge' do
              expect(page).to have_content("Pipeline ##{pipeline.id} failed")

              wait_for_requests

              page.within('.mr-state-widget') do
                expect(page).to have_content('to be merged automatically')
              end
            end
          end

          context 'when CI is canceled' do
            before do
              pipeline.set_status('canceled')
            end

            it 'MR remains set to auto-merge' do
              expect(page).to have_content("Pipeline ##{pipeline.id} canceled")

              wait_for_requests

              page.within('.mr-state-widget') do
                expect(page).to have_content('to be merged automatically')
              end
            end
          end
        end
      end

      context 'when CI succeeded' do
        let(:status) { :success }

        it 'allows MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          page.within('.mr-state-widget') do
            expect(page).to have_button 'Merge'
          end
        end
      end
    end
  end
end
