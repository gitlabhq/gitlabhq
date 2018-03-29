require 'spec_helper'

describe Projects::RawController do
  let(:public_project) { create(:project, :public, :repository) }

  describe '#show' do
    context 'regular filename' do
      let(:id) { 'master/README.md' }

      it 'delivers ASCII file' do
        get_show(public_project, id)

        expect(response).to have_gitlab_http_status(200)
        expect(response.header['Content-Type']).to eq('text/plain; charset=utf-8')
        expect(response.header['Content-Disposition'])
            .to eq('inline')
        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
      end
    end

    context 'image header' do
      let(:id) { 'master/files/images/6049019_460s.jpg' }

      it 'sets image content type header' do
        get_show(public_project, id)

        expect(response).to have_gitlab_http_status(200)
        expect(response.header['Content-Type']).to eq('image/jpeg')
        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
      end
    end

    context 'lfs object' do
      let(:id) { 'be93687/files/lfs/lfs_object.iso' }
      let!(:lfs_object) { create(:lfs_object, oid: '91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897', size: '1575078') }

      context 'when lfs is enabled' do
        before do
          allow_any_instance_of(Project).to receive(:lfs_enabled?).and_return(true)
        end

        context 'when project has access' do
          before do
            public_project.lfs_objects << lfs_object
            allow_any_instance_of(LfsObjectUploader).to receive(:exists?).and_return(true)
            allow(controller).to receive(:send_file) { controller.head :ok }
          end

          it 'serves the file' do
            expect(controller).to receive(:send_file).with("#{LfsObjectUploader.root}/91/ef/f75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897", filename: 'lfs_object.iso', disposition: 'attachment')
            get_show(public_project, id)

            expect(response).to have_gitlab_http_status(200)
          end

          context 'and lfs uses object storage' do
            before do
              lfs_object.file = fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "`/png")
              lfs_object.save!
              stub_lfs_object_storage
              lfs_object.file.migrate!(LfsObjectUploader::Store::REMOTE)
            end

            it 'responds with redirect to file' do
              get_show(public_project, id)

              expect(response).to have_gitlab_http_status(302)
              expect(response.location).to include(lfs_object.reload.file.path)
            end

            it 'sets content disposition' do
              get_show(public_project, id)

              file_uri = URI.parse(response.location)
              params = CGI.parse(file_uri.query)

              expect(params["response-content-disposition"].first).to eq 'attachment;filename="lfs_object.iso"'
            end
          end
        end

        context 'when project does not have access' do
          it 'does not serve the file' do
            get_show(public_project, id)

            expect(response).to have_gitlab_http_status(404)
          end
        end
      end

      context 'when lfs is not enabled' do
        before do
          allow_any_instance_of(Project).to receive(:lfs_enabled?).and_return(false)
        end

        it 'delivers ASCII file' do
          get_show(public_project, id)

          expect(response).to have_gitlab_http_status(200)
          expect(response.header['Content-Type']).to eq('text/plain; charset=utf-8')
          expect(response.header['Content-Disposition'])
              .to eq('inline')
          expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
        end
      end
    end
  end

  def get_show(project, id)
    get(:show, namespace_id: project.namespace.to_param,
               project_id: project,
               id: id)
  end
end
