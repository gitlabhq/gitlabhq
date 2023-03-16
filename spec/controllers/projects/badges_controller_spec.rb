# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BadgesController do
  let_it_be(:project, reload: true) { create(:project, :repository) }
  let_it_be(:pipeline, reload: true) { create(:ci_empty_pipeline, project: project) }
  let_it_be(:user) { create(:user) }

  shared_context 'renders badge irrespective of project access levels' do |badge_type|
    context 'when project is public' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      end

      it "returns the #{badge_type} badge to unauthenticated users" do
        get_badge(badge_type)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when project is restricted' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
        project.add_guest(user)
        sign_in(user)
      end

      it "returns the #{badge_type} badge to guest users" do
        get_badge(badge_type)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  shared_context 'when pipelines are public' do |badge_type|
    before do
      project.update!(public_builds: true)
    end

    it_behaves_like 'renders badge irrespective of project access levels', badge_type
  end

  shared_context 'when pipelines are not public' do |badge_type|
    before do
      project.update!(public_builds: false)
    end

    context 'when project is public' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      end

      it 'returns 404 to unauthenticated users' do
        get_badge(badge_type)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when project is restricted to the user' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
        project.add_guest(user)
        sign_in(user)
      end

      it 'defaults to project permissions' do
        get_badge(badge_type)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_context 'customization' do |badge_type|
    render_views

    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    context 'when key_text param is used' do
      it 'sets custom key text' do
        get_badge(badge_type, key_text: 'custom key text')

        expect(response.body).to include('custom key text')
      end
    end

    context 'when key_width param is used' do
      it 'sets custom key width' do
        get_badge(badge_type, key_width: '123')

        expect(response.body).to include('123')
      end
    end

    if badge_type == :release
      context 'when value_width param is used' do
        it 'sets custom value width' do
          get_badge(badge_type, value_width: '123')

          expect(response.body).to include('123')
        end
      end
    end
  end

  shared_examples 'a badge resource' do |badge_type|
    context 'format' do
      before do
        project.add_maintainer(user)
        sign_in(user)
      end

      it 'renders the `flat` badge layout by default' do
        get_badge(badge_type)

        expect(response).to render_template('projects/badges/badge')
      end

      context 'when style param is set to `flat`' do
        it 'renders the `flat` badge layout' do
          get_badge(badge_type, style: 'flat')

          expect(response).to render_template('projects/badges/badge')
        end
      end

      context 'when style param is set to an invalid type' do
        it 'renders the `flat` (default) badge layout' do
          get_badge(badge_type, style: 'xxx')

          expect(response).to render_template('projects/badges/badge')
        end
      end

      context 'when style param is set to `flat-square`' do
        it 'renders the `flat-square` badge layout' do
          get_badge(badge_type, style: 'flat-square')

          expect(response).to render_template('projects/badges/badge_flat-square')
        end
      end
    end

    it_behaves_like 'customization', badge_type

    if [:pipeline, :coverage].include?(badge_type)
      it_behaves_like 'when pipelines are public', badge_type
      it_behaves_like 'when pipelines are not public', badge_type
    end
  end

  describe '#pipeline' do
    it_behaves_like 'a badge resource', :pipeline

    context 'with ignore_skipped param' do
      render_views

      before do
        pipeline.update!(status: :skipped)
        project.add_maintainer(user)
        sign_in(user)
      end

      it 'returns skipped badge if set to false' do
        get_badge(:pipeline, ignore_skipped: false)
        expect(response.body).to include('skipped')
      end

      it 'does not return skipped badge if set to true' do
        get_badge(:pipeline, ignore_skipped: true)
        expect(response.body).to include('unknown')
      end
    end
  end

  describe '#coverage' do
    it_behaves_like 'a badge resource', :coverage
  end

  describe '#release' do
    action = :release

    it_behaves_like 'a badge resource', action
    it_behaves_like 'renders badge irrespective of project access levels', action
  end

  def get_badge(badge, args = {})
    params = {
      namespace_id: project.namespace.to_param,
      project_id: project,
      ref: pipeline.ref
    }.merge(args.slice(:style, :key_text, :key_width, :value_width, :ignore_skipped))

    get badge, params: params, format: :svg
  end
end
