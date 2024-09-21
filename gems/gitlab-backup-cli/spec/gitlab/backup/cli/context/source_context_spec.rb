# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::Context::SourceContext do
  subject(:context) { described_class.new }

  describe '#env' do
    it 'returns content from RAILS_ENV when its defined' do
      stub_const('ENV', { 'RAILS_ENV' => 'railstest', 'RACK_ENV' => 'racktest' })

      expect(context.env).to eq('railstest')
    end

    it 'returns content from RACK_ENV when its the next one defined' do
      stub_const('ENV', { 'RACK_ENV' => 'racktest' })

      expect(context.env).to eq('racktest')
    end

    it 'returns the default value when no other ENV is defined' do
      stub_const('ENV', {})

      expect(context.env).to eq('development')
    end
  end

  it_behaves_like 'context exposing all common configuration methods'
end
