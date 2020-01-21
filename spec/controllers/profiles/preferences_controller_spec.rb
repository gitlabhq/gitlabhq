# frozen_string_literal: true

require 'spec_helper'

describe Profiles::PreferencesController do
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
    def go(params: {}, format: :js)
      params.reverse_merge!(
        color_scheme_id: '1',
        dashboard: 'stars',
        theme_id: '1'
      )

      patch :update, params: { user: params }, format: format
    end

    context 'on successful update' do
      it 'sets the flash' do
        go
        expect(flash[:notice]).to eq _('Preferences saved.')
      end

      it "changes the user's preferences" do
        prefs = {
          color_scheme_id: '1',
          dashboard: 'stars',
          theme_id: '2',
          first_day_of_week: '1',
          preferred_language: 'jp',
          render_whitespace_in_code: 'true'
        }.with_indifferent_access

        expect(user).to receive(:assign_attributes).with(ActionController::Parameters.new(prefs).permit!)
        expect(user).to receive(:save)

        go params: prefs
      end
    end

    context 'on failed update' do
      it 'sets the flash' do
        expect(user).to receive(:save).and_return(false)

        go

        expect(flash[:alert]).to eq(_('Failed to save preferences.'))
      end
    end

    context 'on invalid dashboard setting' do
      it 'sets the flash' do
        prefs = { dashboard: 'invalid' }

        go params: prefs

        expect(flash[:alert]).to match(/\AFailed to save preferences \(.+\)\.\z/)
      end
    end

    context 'as js' do
      it 'renders' do
        go
        expect(response).to render_template :update
      end
    end

    context 'as html' do
      it 'redirects' do
        go format: :html
        expect(response).to redirect_to(profile_preferences_path)
      end
    end
  end
end
