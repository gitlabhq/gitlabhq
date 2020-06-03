# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BadgesController do
  let(:project) { pipeline.project }
  let!(:pipeline) { create(:ci_empty_pipeline) }
  let(:user) { create(:user) }

  shared_examples 'a badge resource' do |badge_type|
    context 'when pipelines are public' do
      before do
        project.update!(public_builds: true)
      end

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

    context 'when pipelines are not public' do
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

    context 'customization' do
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
    end
  end

  describe '#pipeline' do
    it_behaves_like 'a badge resource', :pipeline
  end

  describe '#coverage' do
    it_behaves_like 'a badge resource', :coverage
  end

  def get_badge(badge, args = {})
    params = {
      namespace_id: project.namespace.to_param,
      project_id: project,
      ref: pipeline.ref
    }.merge(args.slice(:style, :key_text, :key_width))

    get badge, params: params, format: :svg
  end
end
