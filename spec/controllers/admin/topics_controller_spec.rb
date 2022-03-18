# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::TopicsController do
  let_it_be(:topic) { create(:topic, name: 'topic') }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(admin)
  end

  describe 'GET #index' do
    it 'renders the template' do
      get :index

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template('index')
    end

    context 'as a normal user' do
      before do
        sign_in(user)
      end

      it 'renders a 404 error' do
        get :index

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #new' do
    it 'renders the template' do
      get :new

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template('new')
    end

    context 'as a normal user' do
      before do
        sign_in(user)
      end

      it 'renders a 404 error' do
        get :new

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #edit' do
    it 'renders the template' do
      get :edit, params: { id: topic.id }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template('edit')
    end

    context 'as a normal user' do
      before do
        sign_in(user)
      end

      it 'renders a 404 error' do
        get :edit, params: { id: topic.id }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    it 'creates topic' do
      expect do
        post :create, params: { projects_topic: { name: 'test' } }
      end.to change { Projects::Topic.count }.by(1)
    end

    it 'shows error message for invalid topic' do
      post :create, params: { projects_topic: { name: nil } }

      errors = assigns[:topic].errors
      expect(errors).to contain_exactly(errors.full_message(:name, I18n.t('errors.messages.blank')))
    end

    it 'shows error message if topic not unique (case insensitive)' do
      post :create, params: { projects_topic: { name: topic.name.upcase } }

      errors = assigns[:topic].errors
      expect(errors).to contain_exactly(errors.full_message(:name, I18n.t('errors.messages.taken')))
    end

    context 'as a normal user' do
      before do
        sign_in(user)
      end

      it 'renders a 404 error' do
        post :create, params: { projects_topic: { name: 'test' } }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'PUT #update' do
    it 'updates topic' do
      put :update, params: { id: topic.id, projects_topic: { name: 'test' } }

      expect(response).to redirect_to(edit_admin_topic_path(topic))
      expect(topic.reload.name).to eq('test')
    end

    it 'shows error message for invalid topic' do
      put :update, params: { id: topic.id, projects_topic: { name: nil } }

      errors = assigns[:topic].errors
      expect(errors).to contain_exactly(errors.full_message(:name, I18n.t('errors.messages.blank')))
    end

    it 'shows error message if topic not unique (case insensitive)' do
      other_topic = create(:topic, name: 'other-topic')

      put :update, params: { id: topic.id, projects_topic: { name: other_topic.name.upcase } }

      errors = assigns[:topic].errors
      expect(errors).to contain_exactly(errors.full_message(:name, I18n.t('errors.messages.taken')))
    end

    context 'as a normal user' do
      before do
        sign_in(user)
      end

      it 'renders a 404 error' do
        put :update, params: { id: topic.id, projects_topic: { name: 'test' } }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
