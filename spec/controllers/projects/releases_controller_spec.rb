require 'spec_helper'

describe Projects::ReleasesController do
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
      project.releases.destroy_all

      get :edit, namespace_id: project.namespace, project_id: project, tag_id: tag_id

      release = assigns(:release)
      expect(release).not_to be_nil
      expect(release).not_to be_persisted
    end

    it 'retrieves an existing release' do
      get :edit, namespace_id: project.namespace, project_id: project, tag_id: release.tag

      release = assigns(:release)
      expect(release).not_to be_nil
      expect(release).to be_persisted
    end
  end

  describe 'PUT #update' do
    it 'updates release note description' do
      update_release('description updated')

      release = project.releases.find_by_tag(tag)
      expect(release.description).to eq("description updated")
    end

    it 'deletes release note when description is null' do
      expect { update_release('') }.to change(project.releases, :count).by(-1)
    end
  end

  def update_release(description)
    put :update,
      namespace_id: project.namespace.to_param,
      project_id: project,
      tag_id: release.tag,
      release: { description: description }
  end
end
