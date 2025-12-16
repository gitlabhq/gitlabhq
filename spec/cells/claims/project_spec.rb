# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Claim for Project', feature_category: :cell do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  subject! { build(:project, group: group, creator: user) }

  shared_context 'with claims records for Project' do
    def claims_records(only: {})
      claims_records_for(subject, only: only) +
        claims_records_for(subject.route, only: only) +
        claims_records_for(subject.project_namespace, only: only)
    end
  end

  it_behaves_like 'creating new claims' do
    include_context 'with claims records for Project'
  end

  it_behaves_like 'deleting existing claims' do
    include_context 'with claims records for Project'
  end
end
