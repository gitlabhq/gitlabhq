# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DesignManagement::Designs::RawImagesController do
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:viewer) { issue.author }

  let(:design_id) { design.id }
  let(:sha) { design.versions.first.sha }
  let(:filename) { design.filename }

  before do
    enable_design_management
  end

  describe 'GET #show' do
    subject do
      get(:show,
        params: {
          namespace_id: project.namespace,
          project_id: project,
          design_id: design_id,
          sha: sha
      })
    end

    before do
      sign_in(viewer)
    end

    context 'when the design is not an LFS file' do
      let_it_be(:design) { create(:design, :with_file, issue: issue, versions_count: 2) }

      # For security, .svg images should only ever be served with Content-Disposition: attachment.
      # If this specs ever fails we must assess whether we should be serving svg images.
      # See https://gitlab.com/gitlab-org/gitlab/issues/12771
      it 'serves files with `Content-Disposition` header set to attachment plus the filename' do
        subject

        expect(response.header['Content-Disposition']).to match "attachment; filename=\"#{design.filename}\""
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'serves files with Workhorse' do
        subject

        expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
        expect(response).to have_gitlab_http_status(:ok)
      end

      it_behaves_like 'project cache control headers'

      context 'when the user does not have permission' do
        let_it_be(:viewer) { create(:user) }

        specify do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when design does not exist' do
        let(:design_id) { 'foo' }

        specify do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      describe 'sha param' do
        let(:newest_version) { design.versions.ordered.first }
        let(:oldest_version) { design.versions.ordered.last }

        shared_examples 'a successful request for sha' do
          it do
            expect_next_instance_of(DesignManagement::Repository) do |repository|
              expect(repository).to receive(:blob_at).with(expected_ref, design.full_path).and_call_original
            end

            subject

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        specify { expect(newest_version.sha).not_to eq(oldest_version.sha) }

        context 'when sha is the newest version sha' do
          let(:sha) { newest_version.sha }
          let(:expected_ref) { sha }

          it_behaves_like 'a successful request for sha'
        end

        context 'when sha is the oldest version sha' do
          let(:sha) { oldest_version.sha }
          let(:expected_ref) { sha }

          it_behaves_like 'a successful request for sha'
        end

        context 'when sha is nil' do
          let(:sha) { nil }
          let(:expected_ref) { project.design_repository.root_ref }

          it_behaves_like 'a successful request for sha'
        end
      end
    end

    context 'when the design is an LFS file' do
      let_it_be(:design) { create(:design, :with_lfs_file, issue: issue) }

      # For security, .svg images should only ever be served with Content-Disposition: attachment.
      # If this specs ever fails we must assess whether we should be serving svg images.
      # See https://gitlab.com/gitlab-org/gitlab/issues/12771
      it 'serves files with `Content-Disposition: attachment`' do
        subject

        expect(response.header['Content-Disposition']).to eq(%Q(attachment; filename=\"#{filename}\"; filename*=UTF-8''#{filename}))
      end

      it 'sets appropriate caching headers' do
        subject

        expect(response.header['ETag']).to be_present
        expect(response.header['Cache-Control']).to eq("max-age=60, private")
      end
    end

    # Pass `skip_lfs_disabled_tests: true` to this shared example to disable
    # the test scenarios for when LFS is disabled globally.
    #
    # When LFS is disabled then the design management feature also becomes disabled.
    # When the feature is disabled, the `authorize :read_design` check within the
    # controller will never authorize the user. Therefore #show will return a 403 and
    # we cannot test the data that it serves.
    it_behaves_like 'a controller that can serve LFS files', skip_lfs_disabled_tests: true do
      let(:file) { fixture_file_upload('spec/fixtures/dk.png', '`/png') }
      let(:lfs_pointer) { Gitlab::Git::LfsPointerFile.new(file.read) }
      let(:design) { create(:design, :with_lfs_file, file: lfs_pointer.pointer, issue: issue) }
      let(:lfs_oid) { project.design_repository.blob_at('HEAD', design.full_path).lfs_oid }
      let(:filepath) { design.full_path }
    end
  end
end
