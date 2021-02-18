# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::PreferencesController do
  let(:user) { create(:user) }

  before do
    sign_in(user)

    allow(subject).to receive(:current_user).and_return(user)
  end

  describe 'GET show' do
    it 'renders' do
      get :show
      expect(response).to render_template :show
    end

    it 'assigns user' do
      get :show
      expect(assigns[:user]).to eq user
    end
  end

  describe 'PATCH update' do
    def go(params: {}, format: :json)
      params.reverse_merge!(
        color_scheme_id: '1',
        dashboard: 'stars',
        theme_id: '1'
      )

      patch :update, params: { user: params }, format: format
    end

    context 'on successful update' do
      it 'responds with success' do
        go

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.parsed_body['message']).to eq _('Preferences saved.')
        expect(response.parsed_body['type']).to eq('notice')
      end

      it "changes the user's preferences" do
        prefs = {
          color_scheme_id: '1',
          dashboard: 'stars',
          theme_id: '2',
          first_day_of_week: '1',
          preferred_language: 'jp',
          tab_width: '5',
          render_whitespace_in_code: 'true'
        }.with_indifferent_access

        expect(user).to receive(:assign_attributes).with(ActionController::Parameters.new(prefs).permit!)
        expect(user).to receive(:save)

        go params: prefs
      end
    end

    context 'on failed update' do
      it 'responds with error' do
        expect(user).to receive(:save).and_return(false)

        go

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(response.parsed_body['message']).to eq _('Failed to save preferences.')
        expect(response.parsed_body['type']).to eq('alert')
      end
    end

    context 'on invalid dashboard setting' do
      it 'responds with error' do
        prefs = { dashboard: 'invalid' }

        go params: prefs

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(response.parsed_body['message']).to match(/\AFailed to save preferences \(.+\)\.\z/)
        expect(response.parsed_body['type']).to eq('alert')
      end
    end
  end
end
