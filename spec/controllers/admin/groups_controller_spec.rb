# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::GroupsController do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'DELETE #destroy' do
    it 'schedules a group destroy' do
      Sidekiq::Testing.fake! do
        expect { delete :destroy, params: { id: project.group.path } }.to change(GroupDestroyWorker.jobs, :size).by(1)
      end
    end

    it 'redirects to the admin group path' do
      delete :destroy, params: { id: project.group.path }

      expect(response).to redirect_to(admin_groups_path)
    end
  end

  describe 'POST #create' do
    it 'creates group' do
      expect do
        post :create, params: { group: {  path: 'test', name: 'test' } }
      end.to change { Group.count }.by(1)
    end

    it 'creates namespace_settings for group' do
      expect do
        post :create, params: { group: {  path: 'test', name: 'test' } }
      end.to change { NamespaceSetting.count }.by(1)
    end

    it 'creates admin_note for group' do
      expect do
        post :create, params: { group: {  path: 'test', name: 'test', admin_note_attributes: { note: 'test' } } }
      end.to change { Namespace::AdminNote.count }.by(1)
    end

    it 'delegates to Groups::CreateService service instance' do
      expect_next_instance_of(::Groups::CreateService) do |service|
        expect(service).to receive(:execute).once.and_call_original
      end

      post :create, params: { group: { path: 'test', name: 'test' } }
    end
  end

  describe 'PUT #update' do
    subject(:update!) do
      put :update, params: { id: group.to_param, group: { runner_registration_enabled: new_value } }
    end

    context 'with runner registration disabled' do
      let(:runner_registration_enabled) { false }
      let(:new_value) { '1' }

      it 'updates the setting successfully' do
        update!

        expect(response).to have_gitlab_http_status(:found)
        expect(group.reload.runner_registration_enabled).to eq(true)
      end

      it 'does not change the registration token' do
        expect do
          update!
          group.reload
        end.not_to change(group, :runners_token)
      end
    end

    context 'with runner registration enabled' do
      let(:runner_registration_enabled) { true }
      let(:new_value) { '0' }

      it 'updates the setting successfully' do
        update!

        expect(response).to have_gitlab_http_status(:found)
        expect(group.reload.runner_registration_enabled).to eq(false)
      end

      it 'changes the registration token' do
        expect do
          update!
          group.reload
        end.to change(group, :runners_token)
      end
    end
  end
end
