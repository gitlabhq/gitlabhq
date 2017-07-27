require 'spec_helper'

describe Projects::MirrorsController do
  describe 'setting up a remote mirror' do
    context 'when the current project is a mirror' do
      let(:project) { create(:project, :mirror) }

      before do
        sign_in(project.owner)
      end

      it 'allows to create a remote mirror' do
        expect_any_instance_of(EE::Project).to receive(:force_import_job!)

        expect do
          do_put(project, remote_mirrors_attributes: { '0' => { 'enabled' => 1, 'url' => 'http://foo.com' } })
        end.to change { RemoteMirror.count }.to(1)
      end

      context 'when remote mirror has the same URL' do
        it 'does not allow to create the remote mirror' do
          expect do
            do_put(project, remote_mirrors_attributes: { '0' => { 'enabled' => 1, 'url' => project.import_url } })
          end.not_to change { RemoteMirror.count }
        end

        context 'with disabled local mirror' do
          it 'allows to create a remote mirror' do
            expect do
              do_put(project, mirror: 0, remote_mirrors_attributes: { '0' => { 'enabled' => 1, 'url' => project.import_url } })
            end.to change { RemoteMirror.count }.to(1)
          end
        end
      end
    end

    context 'when the current project is not a mirror' do
      it 'allows to create a remote mirror' do
        project = create(:project)
        sign_in(project.owner)

        expect do
          do_put(project, remote_mirrors_attributes: { '0' => { 'enabled' => 1, 'url' => 'http://foo.com' } })
        end.to change { RemoteMirror.count }.to(1)
      end
    end

    context 'when the current project has a remote mirror' do
      let(:project) { create(:project) }
      let(:remote_mirror) { project.remote_mirrors.create!(enabled: 1, url: 'http://local.dev') }

      before do
        sign_in(project.owner)
      end

      context 'when trying to create a mirror with the same URL' do
        it 'should not setup the mirror' do
          do_put(project, mirror: true, import_url: remote_mirror.url)

          expect(project.reload.mirror).to be_falsey
          expect(project.reload.import_url).to be_blank
        end
      end

      context 'when trying to create a mirror with a different URL' do
        it 'should setup the mirror' do
          expect_any_instance_of(EE::Project).to receive(:force_import_job!)

          do_put(project, mirror: true, mirror_user_id: project.owner.id, import_url: 'http://local.dev')

          expect(project.reload.mirror).to eq(true)
          expect(project.reload.import_url).to eq('http://local.dev')
        end

        context 'mirror user is not the current user' do
          it 'should only assign the current user' do
            expect_any_instance_of(EE::Project).to receive(:force_import_job!)

            new_user = create(:user)
            project.add_master(new_user)

            do_put(project, mirror: true, mirror_user_id: new_user.id, import_url: 'http://local.dev')

            expect(project.reload.mirror).to eq(true)
            expect(project.reload.mirror_user.id).to eq(project.owner.id)
          end
        end
      end
    end
  end

  describe 'setting up a mirror' do
    before do
      sign_in(project.owner)
    end

    context 'when project does not have a mirror' do
      let(:project) { create(:project) }

      it 'allows to create a mirror' do
        expect_any_instance_of(EE::Project).to receive(:force_import_job!)

        expect do
          do_put(project, mirror: true, mirror_user_id: project.owner.id, import_url: 'http://foo.com')
        end.to change { Project.mirror.count }.to(1)
      end
    end

    context 'when project has a mirror' do
      let(:project) { create(:project, :mirror, :import_finished) }

      it 'is able to disable the mirror' do
        expect { do_put(project, mirror: false) }.to change { Project.mirror.count }.to(0)
      end
    end
  end

  describe 'forcing an update' do
    it 'forces update' do
      expect_any_instance_of(EE::Project).to receive(:force_import_job!)

      project = create(:project, :mirror)
      sign_in(project.owner)

      put :update_now, { namespace_id: project.namespace.to_param, project_id: project.to_param }
    end
  end

  def do_put(project, options)
    attrs = { namespace_id: project.namespace.to_param, project_id: project.to_param }
    attrs[:project] = options

    put :update, attrs
  end
end
