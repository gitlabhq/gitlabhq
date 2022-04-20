# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Instance-level AWS EKS Cluster', :js do
  let(:user) { create(:admin) }

  before do
    sign_in(user)
    gitlab_enable_admin_mode_sign_in(user)
    stub_application_setting(eks_integration_enabled: true)
  end

  context 'when user does not have a cluster and visits group clusters page' do
    before do
      visit admin_clusters_path

      click_button(class: 'dropdown-toggle-split')
      click_link 'Create a cluster (deprecated)'
    end

    context 'when user creates a cluster on AWS EKS' do
      before do
        click_link 'Amazon EKS'
      end

      it 'user sees a form to create an EKS cluster' do
        expect(page).to have_content('Authenticate with Amazon Web Services')
      end
    end
  end
end
