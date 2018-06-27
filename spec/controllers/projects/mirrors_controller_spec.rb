require 'spec_helper'

describe Projects::MirrorsController do
  include ReactiveCachingHelpers

  describe 'setting up a remote mirror' do
    set(:project) { create(:project, :repository) }

    context 'when the current project is not a mirror' do
      it 'allows to create a remote mirror' do
        sign_in(project.owner)

        expect do
          do_put(project, remote_mirrors_attributes: { '0' => { 'enabled' => 1, 'url' => 'http://foo.com' } })
        end.to change { RemoteMirror.count }.to(1)
      end
    end
  end

  describe '#update' do
    let(:project) { create(:project, :repository, :remote_mirror) }

    before do
      sign_in(project.owner)
    end

    around do |example|
      Sidekiq::Testing.fake! { example.run }
    end

    context 'With valid URL for a push' do
      let(:remote_mirror_attributes) do
        { "0" => { "enabled" => "0", url: 'https://updated.example.com' } }
      end

      it 'processes a successful update' do
        do_put(project, remote_mirrors_attributes: remote_mirror_attributes)

        expect(response).to redirect_to(project_settings_repository_path(project))
        expect(flash[:notice]).to match(/successfully updated/)
      end

      it 'should create a RemoteMirror object' do
        expect { do_put(project, remote_mirrors_attributes: remote_mirror_attributes) }.to change(RemoteMirror, :count).by(1)
      end
    end

    context 'With invalid URL for a push' do
      let(:remote_mirror_attributes) do
        { "0" => { "enabled" => "0", url: 'ftp://invalid.invalid' } }
      end

      it 'processes an unsuccessful update' do
        do_put(project, remote_mirrors_attributes: remote_mirror_attributes)

        expect(response).to redirect_to(project_settings_repository_path(project))
        expect(flash[:alert]).to match(/Only allowed protocols are/)
      end

      it 'should not create a RemoteMirror object' do
        expect { do_put(project, remote_mirrors_attributes: remote_mirror_attributes) }.not_to change(RemoteMirror, :count)
      end
    end
  end

  def do_put(project, options, extra_attrs = {})
    attrs = extra_attrs.merge(namespace_id: project.namespace.to_param, project_id: project.to_param)
    attrs[:project] = options

    put :update, attrs
  end
end
