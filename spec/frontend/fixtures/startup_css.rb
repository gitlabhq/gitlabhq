# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Startup CSS fixtures', type: :controller do
  include JavaScriptFixturesHelpers

  let(:use_full_html) { true }

  render_views

  before(:all) do
    stub_feature_flags(combined_menu: true)
    stub_feature_flags(sidebar_refactor: true)
    clean_frontend_fixtures('startup_css/')
  end

  shared_examples 'startup css project fixtures' do |type|
    let(:user) { create(:user, :admin) }
    let(:project) { create(:project, :public, :repository, description: 'Code and stuff', creator: user) }

    before do
      sign_in(user)
    end

    it "startup_css/project-#{type}-legacy-menu.html" do
      stub_feature_flags(combined_menu: false)

      get :show, params: {
        namespace_id: project.namespace.to_param,
        id: project
      }

      expect(response).to be_successful
    end

    it "startup_css/project-#{type}.html" do
      get :show, params: {
        namespace_id: project.namespace.to_param,
        id: project
      }

      expect(response).to be_successful
    end

    it "startup_css/project-#{type}-legacy-sidebar.html" do
      stub_feature_flags(sidebar_refactor: false)

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
  end

  describe ProjectsController, '(Startup CSS fixtures)', type: :controller do
    it_behaves_like 'startup css project fixtures', 'general'
  end

  describe ProjectsController, '(Startup CSS fixtures)', type: :controller do
    before do
      user.update!(theme_id: 11)
    end

    it_behaves_like 'startup css project fixtures', 'dark'
  end

  describe RegistrationsController, '(Startup CSS fixtures)', type: :controller do
    it 'startup_css/sign-in.html' do
      get :new

      expect(response).to be_successful
    end
  end
end
