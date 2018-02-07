require 'rails_helper'

describe Projects::PathLocksController, type: :request do
  let(:project) { create(:project, :repository) }
  let(:user)    { project.owner }
  let(:viewer)  { user }

  before do
    login_as(viewer)
  end

  describe 'POST #toggle' do
    context 'when locking a file' do
      context 'when LFS is enabled' do
        before do
          allow_any_instance_of(Projects::PathLocksController).to receive(:sync_with_lfs?).and_return(true)
        end

        it 'locks the file' do
          expect { toggle_lock('README.md') }.to change { PathLock.count }.to(1)

          expect(response).to have_gitlab_http_status(200)
        end

        it "locks the file in LFS" do
          expect { toggle_lock('README.md') }.to change { LfsFileLock.count }.to(1)
        end
      end

      context 'when LFS is not enabled' do
        it 'locks the file' do
          expect { toggle_lock('README.md') }.to change { PathLock.count }.to(1)

          expect(response).to have_gitlab_http_status(200)
        end

        it "doesn't lock the file in LFS" do
          expect { toggle_lock('README.md') }.not_to change { LfsFileLock.count }
        end
      end
    end

    context 'when unlocking a file' do
      context 'when LFS is enabled' do
        before do
          allow_any_instance_of(Projects::PathLocksController).to receive(:sync_with_lfs?).and_return(true)

          toggle_lock('README.md')
        end

        it 'unlocks the file' do
          expect { toggle_lock('README.md') }.to change { PathLock.count }.to(0)

          expect(response).to have_gitlab_http_status(200)
        end

        it "unlocks the file in LFS" do
          expect { toggle_lock('README.md') }.to change { LfsFileLock.count }.to(0)
        end
      end
    end

    context 'when LFS is not enabled' do
      before do
        toggle_lock('README.md')
      end

      it 'unlocks the file' do
        expect { toggle_lock('README.md') }.to change { PathLock.count }.to(0)

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end

  def toggle_lock(path)
    post toggle_project_path_locks_path(project), path: path
  end
end
