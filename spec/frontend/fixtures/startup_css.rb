# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Startup CSS fixtures', type: :controller do
  include JavaScriptFixturesHelpers

  let(:use_full_html) { true }

  render_views

  shared_examples 'startup css project fixtures' do |type|
    let(:user) { create(:user, :admin) }
    let(:project) { create(:project, :public, :repository, description: 'Code and stuff', creator: user) }

    before do
      # We want vNext badge to be included and com/canary don't remove/hide any other elements.
      # This is why we're turning com and canary on by default for now.
      allow(Gitlab).to receive(:canary?).and_return(true)
      sign_in(user)
    end

    it "startup_css/project-#{type}.html" do
      get :show, params: {
        namespace_id: project.namespace.to_param,
        id: project
      }

      expect(response).to be_successful
    end

    it "startup_css/project-#{type}-signed-out.html" do
      sign_out(user)

      get :show, params: {
        namespace_id: project.namespace.to_param,
        id: project
      }

      expect(response).to be_successful
    end

    # This Feature Flag is off by default
    # This ensures that the correct css is generated for super sidebar
    # When the feature flag is off, the general startup will capture it
    it "startup_css/project-#{type}-super-sidebar.html" do
      stub_feature_flags(super_sidebar_nav: true)
      user.update!(use_new_navigation: true)

      get :show, params: {
        namespace_id: project.namespace.to_param,
        id: project
      }

      expect(response).to be_successful
    end
  end

  describe ProjectsController, '(Startup CSS fixtures)', :saas, type: :controller do
    it_behaves_like 'startup css project fixtures', 'general'
  end

  describe ProjectsController, '(Startup CSS fixtures)', :saas, type: :controller do
    before do
      user.update!(theme_id: 11)
    end

    it_behaves_like 'startup css project fixtures', 'dark'
  end

  describe SessionsController, '(Startup CSS fixtures)', type: :controller do
    include DeviseHelpers

    before do
      set_devise_mapping(context: request)
    end

    it 'startup_css/sign-in.html' do
      get :new

      expect(response).to be_successful
    end

    it 'startup_css/sign-in-old.html' do
      stub_feature_flags(restyle_login_page: false)

      get :new

      expect(response).to be_successful
    end
  end
end
