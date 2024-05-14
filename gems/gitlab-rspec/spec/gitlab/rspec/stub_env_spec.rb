# frozen_string_literal: true

require 'gitlab/rspec/stub_env'

RSpec.describe 'StubENV' do
  include StubENV

  describe '#stub_env' do
    it 'stubs the environment variable for all ways to read it' do
      stub_env('MY_TEST_ENV_VAR', 'the value')

      expect(ENV['MY_TEST_ENV_VAR']).to eq('the value')
      expect(ENV.key?('MY_TEST_ENV_VAR')).to eq(true)
      expect(ENV.fetch('MY_TEST_ENV_VAR')).to eq('the value')
      expect(ENV.fetch('MY_TEST_ENV_VAR', 'some default')).to eq('the value')
    end

    context 'when stubbed to be nil' do
      it 'uses a default value for fetch and raises if no default given' do
        stub_env('MY_TEST_ENV_VAR', nil)

        expect(ENV.fetch('MY_TEST_ENV_VAR', 'some default')).to eq('some default')
        expect { ENV.fetch('MY_TEST_ENV_VAR') }.to raise_error(KeyError)
      end
    end
  end
end
