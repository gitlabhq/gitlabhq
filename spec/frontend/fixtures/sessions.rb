# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sessions (JavaScript fixtures)', feature_category: :system_access do
  include JavaScriptFixturesHelpers

  describe SessionsController, '(JavaScript fixtures)', type: :controller do
    include DeviseHelpers

    render_views

    before do
      set_devise_mapping(context: @request)
    end

    it 'sessions/new.html' do
      stub_feature_flags(sign_in_form_vue: false)
      get :new

      expect(response).to be_successful
    end

    it 'sessions/new_vue.html' do
      get :new

      expect(response).to be_successful
    end
  end
end
