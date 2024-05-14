# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CheckInitialSetup, feature_category: :system_access do
  controller(ApplicationController) do
    # `described_class` is not available in this context
    include CheckInitialSetup

    skip_before_action :authenticate_user!

    def index
      if in_initial_setup_state?
        head :ok
      else
        head :no_content
      end
    end
  end

  shared_examples 'is in_initial_setup_state?' do
    it 'is in_initial_setup_state?' do
      response = get :index

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  shared_examples 'is not in_initial_setup_state?' do
    it 'is not in_initial_setup_state?' do
      response = get :index

      expect(response).to have_gitlab_http_status(:no_content)
    end
  end

  context 'when db is empty' do
    include_examples 'is not in_initial_setup_state?'
  end

  context 'when one admin user named root' do
    let(:username) { 'root' }
    let(:password_automatically_set) { true }

    before do
      create(
        :admin,
        username: username,
        password_automatically_set: password_automatically_set
      )
    end

    include_examples 'is in_initial_setup_state?'

    context 'when username is not root' do
      let(:username) { 'capybara' }

      include_examples 'is in_initial_setup_state?'
    end

    context 'when password reset flag is not set' do
      let(:password_automatically_set) { false }

      include_examples 'is not in_initial_setup_state?'
    end

    context 'when multiple users exist' do
      before do
        create(:user)
      end

      include_examples 'is not in_initial_setup_state?'
    end

    context 'when multiple admins exist' do
      before do
        create(:admin)
      end

      include_examples 'is not in_initial_setup_state?'
    end
  end
end
