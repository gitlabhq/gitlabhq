# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sessions (JavaScript fixtures)' do
  include JavaScriptFixturesHelpers

  before(:all) do
    clean_frontend_fixtures('sessions/')
  end

  describe SessionsController, '(JavaScript fixtures)', type: :controller do
    include DeviseHelpers

    render_views

    before do
      set_devise_mapping(context: @request)
    end

    it 'sessions/new.html' do
      get :new

      expect(response).to be_successful
    end
  end
end
