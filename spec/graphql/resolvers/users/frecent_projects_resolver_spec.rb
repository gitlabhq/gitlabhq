# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Users::FrecentProjectsResolver, feature_category: :navigation do
  it_behaves_like 'namespace visits resolver'
end
