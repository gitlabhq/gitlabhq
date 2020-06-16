# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../spec/features/clusters/installing_applications_shared_examples'

RSpec.describe 'Group-level Cluster Applications', :js do
  include GoogleApi::CloudPlatformHelpers

  let(:group) { create(:group) }
  let(:user) { create(:user) }

  before do
    group.add_maintainer(user)
    sign_in(user)
  end

  describe 'Installing applications' do
    include_examples "installing applications on a cluster" do
      let(:cluster_path) { group_cluster_path(group, cluster) }
      let(:cluster_factory_args) { [:group, groups: [group]] }
    end
  end
end
