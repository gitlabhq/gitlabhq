require 'spec_helper'

describe Projects::LfsStorageController do
  include ApiHelpers

  set(:user) { create(:user) }
  set(:project) { create(:project, :public, :repository) }

  before do
    project.add_developer(user)

    sign_in(user)
  end

  describe 'PUT #upload_finalize' do
    let(:params) {  }

    content 'when lfs_object does not exist' do
      let(:file_path) { 'aiueo' }
      let(:oid) { Digest::SHA256.hexdigest 'abc' }
      let(:size) { 499013 }

      it 'creates a new object' do
        expect { go }.to change { LfsObject.count }.by(1)

        expect(response).to have_gitlab_http_status(200)
        expect(LfsObject.last.file_identifier).to eq()
      end
    end

    content 'when lfs_object exists' do
      before do
        create(:lfs_object)
      end

      it 'returns a new object' do
        expect { go }.not_to change { LfsObject.count }

      end
    end

    def go
      put :upload_finalize, params
    end
  end
end
