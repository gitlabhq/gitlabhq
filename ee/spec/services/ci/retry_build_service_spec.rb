# frozen_string_literal: true
require 'spec_helper'

describe Ci::RetryBuildService do
  it_behaves_like 'restricts access to protected environments'
end
