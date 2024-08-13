# frozen_string_literal: true

require 'spec_helper'
require 'thor'

RSpec.describe Gitlab::Backup::Cli::Commands::BackupSubcommand do
  describe "#executor_options" do
    it "returns the expected hash" do
      expect(described_class.new.send(:executor_options).keys).to eq(
        %w[wait_for_completion service_account_file]
      )
    end
  end
end
