# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistryHelper do
  describe '#container_repository_gid_prefix' do
    subject { helper.container_repository_gid_prefix }

    it { is_expected.to eq('gid://gitlab/ContainerRepository/') }
  end
end
