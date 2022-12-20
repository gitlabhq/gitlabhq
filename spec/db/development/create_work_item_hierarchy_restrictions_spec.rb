# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create work item hierarchy restrictions in development', feature_category: :portfolio_management do
  subject { load Rails.root.join('db/fixtures/development/50_create_work_item_hierarchy_restrictions.rb') }

  it_behaves_like 'work item hierarchy restrictions importer'
end
