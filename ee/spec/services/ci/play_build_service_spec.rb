# frozen_string_literal: true
require 'spec_helper'

describe Ci::PlayBuildService, '#execute' do
  it_behaves_like 'restricts access to protected environments'
end
