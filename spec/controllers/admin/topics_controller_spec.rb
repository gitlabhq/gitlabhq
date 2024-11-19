# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::TopicsController, :with_current_organization do
  let_it_be(:namespace) { create :namespace, organization: current_organization }
  let_it_be(:topic) { create(:topic, name: 'topic', organization: namespace.organization) }
  let_it_be(:admin) { create(:admin, namespace: namespace) }
  let_it_be(:user) { create(:user, namespace: namespace) }

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
        post :create, params: { projects_topic: { name: 'test', title: 'Test' } }
      end.to change { Projects::Topic.for_organization(current_organization.id).count }.by(1)
    end

    it 'shows error message for invalid topic name' do
      post :create, params: { projects_topic: { name: nil, title: 'Test' } }

      errors = assigns[:topic].errors
      expect(errors).to contain_exactly(errors.full_message(:name, I18n.t('errors.messages.blank')))
    end

    it 'shows error message if topic name not unique (case insensitive)' do
      post :create, params: { projects_topic: { name: topic.name.upcase, title: topic.title } }

      errors = assigns[:topic].errors
      expect(errors).to contain_exactly(errors.full_message(:name, I18n.t('errors.messages.taken')))
    end

    it 'shows error message for invalid topic title' do
      post :create, params: { projects_topic: { name: 'test', title: nil } }

      errors = assigns[:topic].errors
      expect(errors).to contain_exactly(errors.full_message(:title, I18n.t('errors.messages.blank')))
    end

    it 'redirects to the topics list' do
      post :create, params: { projects_topic: { name: 'test-redirect', title: "Test redirect" } }

      expect(response).to redirect_to(admin_topics_path)
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
      other_topic = create(:topic, name: 'other-topic', organization: current_organization)

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

  describe 'DELETE #destroy' do
    it 'removes topic' do
      delete :destroy, params: { id: topic.id }

      expect(response).to redirect_to(admin_topics_path)
      expect { topic.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'as a normal user' do
      before do
        sign_in(user)
      end

      it 'renders a 404 error' do
        delete :destroy, params: { id: topic.id }

        expect(response).to have_gitlab_http_status(:not_found)
        expect { topic.reload }.not_to raise_error
      end
    end
  end

  describe 'POST #merge' do
    let_it_be(:source_topic) { create(:topic, name: 'source_topic', organization: current_organization) }
    let_it_be(:project) { create(:project, topic_list: source_topic.name, organization: current_organization) }

    let_it_be(:new_organization) { create(:organization, name: 'New Organization') }
    let_it_be(:new_organization_topic) { create(:topic, name: 'new_org_topic', organization: new_organization) }

    it 'merges source topic into target topic' do
      post :merge, params: { source_topic_id: source_topic.id, target_topic_id: topic.id }

      expect(response).to redirect_to(admin_topics_path)
      expect(topic.projects).to contain_exactly(project)
      expect { source_topic.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'renders a 404 error for non-existing id' do
      post :merge, params: { source_topic_id: non_existing_record_id, target_topic_id: topic.id }

      expect(response).to have_gitlab_http_status(:not_found)
      expect { topic.reload }.not_to raise_error
    end

    it 'renders a 400 error for identical topic ids' do
      post :merge, params: { source_topic_id: topic.id, target_topic_id: topic.id }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect { topic.reload }.not_to raise_error
    end

    it 'renders a 400 error when trying to merge topics from different organizations' do
      post :merge, params: { source_topic_id: source_topic.id, target_topic_id: new_organization_topic.id }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect { source_topic.reload }.not_to raise_error
      expect { new_organization_topic.reload }.not_to raise_error
    end

    context 'as a normal user' do
      before do
        sign_in(user)
      end

      it 'renders a 404 error' do
        post :merge, params: { source_topic_id: source_topic.id, target_topic_id: topic.id }

        expect(response).to have_gitlab_http_status(:not_found)
        expect { source_topic.reload }.not_to raise_error
      end
    end
  end
end
