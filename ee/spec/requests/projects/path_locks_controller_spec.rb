require 'rails_helper'

describe Projects::PathLocksController, type: :request do
  let(:project) { create(:project, :repository) }
  let(:user)    { project.owner }
  let(:viewer)  { user }
  let(:file_path) { 'files/lfs/lfs_object.iso' }
  let(:blob_object) { project.repository.blob_at_branch('lfs', file_path) }
  let!(:lfs_object) { create(:lfs_object, oid: blob_object.lfs_oid) }
  let!(:lfs_objects_project) { create(:lfs_objects_project, project: project, lfs_object: lfs_object) }

  before do
    login_as(viewer)

    allow_any_instance_of(Repository).to receive(:root_ref).and_return('lfs')
  end

  describe 'POST #toggle' do
    context 'when LFS is enabled' do
      before do
        allow_any_instance_of(Project).to receive(:lfs_enabled?).and_return(true)
      end

      context 'when locking a file' do
        it 'locks the file' do
          toggle_lock(file_path)

          expect(PathLock.count).to eq(1)
          expect(response).to have_gitlab_http_status(200)
        end

        it "locks the file in LFS" do
          expect { toggle_lock(file_path) }.to change { LfsFileLock.count }.to(1)
        end

        it "tries to create the PathLock only once" do
          expect(PathLocks::LockService).to receive(:new).once.and_return(double.as_null_object)

          toggle_lock(file_path)
        end
      end

      context 'when locking a directory' do
        it 'locks the directory' do
          expect { toggle_lock('bar/') }.to change { PathLock.count }.to(1)

          expect(response).to have_gitlab_http_status(200)
        end

        it 'does not locks the directory through LFS' do
          expect { toggle_lock('bar/') }.not_to change { LfsFileLock.count }

          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'when unlocking a file' do
        context 'with files' do
          before do
            toggle_lock(file_path)
          end

          it 'unlocks the file' do
            expect { toggle_lock(file_path) }.to change { PathLock.count }.to(0)

            expect(response).to have_gitlab_http_status(200)
          end

          it "unlocks the file in LFS" do
            expect { toggle_lock(file_path) }.to change { LfsFileLock.count }.to(0)
          end
        end
      end

      context 'when unlocking a directory' do
        before do
          toggle_lock('bar')
        end

        it 'unlocks the directory' do
          expect { toggle_lock('bar') }.to change { PathLock.count }.to(0)

          expect(response).to have_gitlab_http_status(200)
        end

        it 'does not call the LFS unlock service' do
          expect(Lfs::UnlockFileService).not_to receive(:new)

          toggle_lock('bar')
        end
      end
    end

    context 'when LFS is not enabled' do
      it 'locks the file' do
        expect { toggle_lock(file_path) }.to change { PathLock.count }.to(1)

        expect(response).to have_gitlab_http_status(200)
      end

      it "doesn't lock the file in LFS" do
        expect { toggle_lock(file_path) }.not_to change { LfsFileLock.count }
      end

      it 'unlocks the file' do
        toggle_lock(file_path)

        expect { toggle_lock(file_path) }.to change { PathLock.count }.to(0)

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end

  def toggle_lock(path)
    post toggle_project_path_locks_path(project), path: path
  end
end
