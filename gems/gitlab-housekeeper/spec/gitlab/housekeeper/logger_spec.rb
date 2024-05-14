# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'gitlab/housekeeper/logger'

RSpec.describe ::Gitlab::Housekeeper::Logger do
  let(:output) { StringIO.new }
  let(:logged) { output.string }

  subject(:logger) { described_class.new(output) }

  describe 'formatting' do
    it 'only prints severity and message' do
      logger.info
      logger.debug 42
      logger.error RuntimeError.new('test')
      logger.warn :hello

      expect(logged).to eq(<<~OUTPUT)
        INFO: nil
        DEBUG: 42
        ERROR: test (RuntimeError)

        WARN: :hello
      OUTPUT
    end
  end

  describe '#puts' do
    it 'mimics Kernel#puts and logs without any tags' do
      logger.puts
      logger.puts :hello
      logger.puts "world"

      expect(logged).to eq(<<~OUTPUT)

        hello
        world
      OUTPUT
    end
  end

  %i[debug info warn error fatal].each do |severity|
    describe "##{severity}" do
      it 'tags message with severity only' do
        tag = severity.to_s.upcase

        logger.public_send(severity, :hello)

        expect(logged).to eq("#{tag}: :hello\n")
      end
    end
  end
end
