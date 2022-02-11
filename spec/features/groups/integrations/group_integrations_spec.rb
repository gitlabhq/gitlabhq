# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group integrations', :js do
  include_context 'group integration activation'

  it_behaves_like 'integration settings form' do
    let(:integrations) { Integration.find_or_initialize_all_non_project_specific(Integration.for_group(group)) }

    def navigate_to_integration(integration)
      visit_group_integration(integration.title)
    end
  end
end
