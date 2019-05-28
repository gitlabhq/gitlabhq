# frozen_string_literal: true

require 'spec_helper'

describe Projects::BadgesController do
  let(:project) { pipeline.project }
  let!(:pipeline) { create(:ci_empty_pipeline) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  it 'requests the pipeline badge successfully' do
    get_badge(:pipeline)

    expect(response).to have_gitlab_http_status(:ok)
  end

  it 'requests the coverage badge successfully' do
    get_badge(:coverage)

    expect(response).to have_gitlab_http_status(:ok)
  end

  it 'renders the `flat` badge layout by default' do
    get_badge(:coverage)

    expect(response).to render_template('projects/badges/badge')
  end

  context 'when style param is set to `flat`' do
    it 'renders the `flat` badge layout' do
      get_badge(:coverage, 'flat')

      expect(response).to render_template('projects/badges/badge')
    end
  end

  context 'when style param is set to an invalid type' do
    it 'renders the `flat` (default) badge layout' do
      get_badge(:coverage, 'xxx')

      expect(response).to render_template('projects/badges/badge')
    end
  end

  context 'when style param is set to `flat-square`' do
    it 'renders the `flat-square` badge layout' do
      get_badge(:coverage, 'flat-square')

      expect(response).to render_template('projects/badges/badge_flat-square')
    end
  end

  def get_badge(badge, style = nil)
    params = {
      namespace_id: project.namespace.to_param,
      project_id: project,
      ref: pipeline.ref,
      style: style
    }

    get badge, params: params, format: :svg
  end
end
