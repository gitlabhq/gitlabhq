require 'spec_helper'

describe Service do
  describe 'Available services' do
    it { expect(described_class.available_services_names).to include("jenkins", "jira") }
  end
end
