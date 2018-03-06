require 'spec_helper'

feature 'Pages' do
  given(:project) { create(:project) }
  given(:user) { create(:user) }
  given(:role) { :master }

  background do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)

    project.add_role(user, role)

    sign_in(user)
  end

  shared_examples 'no pages deployed' do
    scenario 'does not see anything to destroy' do
      visit project_pages_path(project)

      expect(page).not_to have_link('Remove pages')
      expect(page).not_to have_text('Only the project owner can remove pages')
    end
  end

  context 'when user is the owner' do
    background do
      project.namespace.update(owner: user)
    end

    context 'when pages deployed' do
      background do
        allow_any_instance_of(Project).to receive(:pages_deployed?) { true }
      end

      scenario 'sees "Remove pages" link' do
        visit project_pages_path(project)

        expect(page).to have_link('Remove pages')
      end
    end

    it_behaves_like 'no pages deployed'
  end

  context 'when the user is not the owner' do
    context 'when pages deployed' do
      background do
        allow_any_instance_of(Project).to receive(:pages_deployed?) { true }
      end

      scenario 'sees "Only the project owner can remove pages" text' do
        visit project_pages_path(project)

        expect(page).to have_text('Only the project owner can remove pages')
      end
    end

    it_behaves_like 'no pages deployed'
  end

  describe 'Remove page' do
    context 'when user is the owner' do
      let(:project) { create :project, :repository }

      before do
        project.namespace.update(owner: user)
      end

      context 'when pages are deployed' do
        let(:pipeline) do
          commit_sha = project.commit('HEAD').sha

          project.pipelines.create(
            ref: 'HEAD',
            sha: commit_sha,
            source: :push,
            protected: false
          )
        end

        let(:ci_build) do
          create(
            :ci_build,
            project: project,
            pipeline: pipeline,
            ref: 'HEAD',
            legacy_artifacts_file: fixture_file_upload(Rails.root.join('spec/fixtures/pages.zip')),
            legacy_artifacts_metadata: fixture_file_upload(Rails.root.join('spec/fixtures/pages.zip.meta'))
          )
        end

        before do
          result = Projects::UpdatePagesService.new(project, ci_build).execute
          expect(result[:status]).to eq(:success)
          expect(project).to be_pages_deployed
        end

        it 'removes the pages' do
          visit project_pages_path(project)

          expect(page).to have_link('Remove pages')

          click_link 'Remove pages'

          expect(project.pages_deployed?).to be_falsey
        end
      end
    end
  end
end
