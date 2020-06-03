# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Tags::ReleasesController do
  let!(:project) { create(:project, :repository) }
  let!(:user)    { create(:user) }
  let!(:release) { create(:release, project: project) }
  let!(:tag)     { release.tag }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  describe 'GET #edit' do
    it 'initializes a new release' do
      tag_id = release.tag
      project.releases.destroy_all # rubocop: disable Cop/DestroyAll

      response = get :edit, params: { namespace_id: project.namespace, project_id: project, tag_id: tag_id }

      release = assigns(:release)
      expect(release).not_to be_nil
      expect(release).not_to be_persisted
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'retrieves an existing release' do
      response = get :edit, params: { namespace_id: project.namespace, project_id: project, tag_id: release.tag }

      release = assigns(:release)
      expect(release).not_to be_nil
      expect(release).to be_persisted
      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'PUT #update' do
    it 'updates release note description' do
      response = update_release(release.tag, "description updated")

      release = project.releases.find_by(tag: tag)
      expect(release.description).to eq("description updated")
      expect(response).to have_gitlab_http_status(:found)
    end

    it 'creates a release if one does not exist' do
      tag_without_release = create_new_tag

      expect do
        update_release(tag_without_release.name, "a new release")
      end.to change { project.releases.count }.by(1)

      expect(response).to have_gitlab_http_status(:found)
    end

    it 'sets the release name, sha, and author for a new release' do
      tag_without_release = create_new_tag

      response = update_release(tag_without_release.name, "a new release")

      release = project.releases.find_by(tag: tag_without_release.name)
      expect(release.name).to eq(tag_without_release.name)
      expect(release.sha).to eq(tag_without_release.target_commit.sha)
      expect(release.author.id).to eq(user.id)
      expect(response).to have_gitlab_http_status(:found)
    end

    it 'does not delete release when description is empty' do
      expect do
        update_release(tag, "")
      end.not_to change { project.releases.count }

      expect(release.reload.description).to eq("")

      expect(response).to have_gitlab_http_status(:found)
    end

    it 'does nothing when description is empty and the tag does not have a release' do
      tag_without_release = create_new_tag

      expect do
        update_release(tag_without_release.name, "")
      end.not_to change { project.releases.count }

      expect(response).to have_gitlab_http_status(:found)
    end
  end

  def create_new_tag
    project.repository.add_tag(user, 'mytag', 'master')
  end

  def update_release(tag_id, description)
    put :update, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      tag_id: tag_id,
      release: { description: description }
    }
  end
end
