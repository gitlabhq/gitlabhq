# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::MergeRequests::SetSubscription do
  it_behaves_like 'a subscribeable graphql resource' do
    let_it_be(:resource) { create(:merge_request) }
    let(:permission_name) { :update_merge_request }
  end
end
