# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Backup::Cli do
  it "has a version number" do
    expect(Gitlab::Backup::Cli::VERSION).not_to be nil
  end
end
