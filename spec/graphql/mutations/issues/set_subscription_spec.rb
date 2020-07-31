# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::SetSubscription do
  it_behaves_like 'a subscribeable graphql resource' do
    let_it_be(:resource) { create(:issue) }
    let(:permission_name) { :update_issue }
  end
end
