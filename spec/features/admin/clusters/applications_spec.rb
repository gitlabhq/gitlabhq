# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../spec/features/clusters/installing_applications_shared_examples'

describe 'Instance-level Cluster Applications', :js do
  include GoogleApi::CloudPlatformHelpers

  let(:user) { create(:admin) }

  before do
    sign_in(user)
  end

  describe 'Installing applications' do
    include_examples "installing applications on a cluster" do
      let(:cluster_path) { admin_cluster_path(cluster) }
      let(:cluster_factory_args) { [:instance] }
    end
  end
end
