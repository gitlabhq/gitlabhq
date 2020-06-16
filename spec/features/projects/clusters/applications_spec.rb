# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../spec/features/clusters/installing_applications_shared_examples'

RSpec.describe 'Project-level Cluster Applications', :js do
  include GoogleApi::CloudPlatformHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'Installing applications' do
    include_examples "installing applications on a cluster" do
      let(:cluster_path) { project_cluster_path(project, cluster) }
      let(:cluster_factory_args) { [projects: [project]] }
    end
  end
end
