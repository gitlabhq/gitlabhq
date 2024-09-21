# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::Context do
  subject(:context) { described_class }

  describe '.build' do
    context 'when omnibus context environment is available' do
      it 'returns an OmnibusContext instance' do
        omnibus_context = Gitlab::Backup::Cli::Context::OmnibusContext

        allow(omnibus_context).to receive(:available?).and_return(true)

        expect(context.build).to be_a(omnibus_context)
      end
    end

    context 'when omnibus context is not available' do
      it 'returns a SourceContext instance' do
        expect(context.build).to be_a(Gitlab::Backup::Cli::Context::SourceContext)
      end
    end
  end
end
