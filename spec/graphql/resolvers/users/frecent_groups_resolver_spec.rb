# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Users::FrecentGroupsResolver, feature_category: :navigation do
  it_behaves_like 'namespace visits resolver'
end
