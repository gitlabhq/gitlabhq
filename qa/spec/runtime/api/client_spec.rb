# frozen_string_literal: true

RSpec.describe QA::Runtime::API::Client do
  include Helpers::StubENV

  describe 'initialization' do
    it 'defaults to :gitlab address' do
      expect(described_class.new.address).to eq :gitlab
    end

    it 'uses specified address' do
      client = described_class.new('http:///example.com')

      expect(client.address).to eq 'http:///example.com'
    end
  end

  describe '#personal_access_token' do
    context 'when user is nil and QA::Runtime::Env.personal_access_token is present' do
      before do
        allow(QA::Runtime::Env).to receive(:personal_access_token).and_return('a_token')
      end

      it 'returns specified token from env' do
        expect(subject.personal_access_token).to eq 'a_token'
      end
    end

    context 'when user is present and QA::Runtime::Env.personal_access_token is nil' do
      before do
        allow(QA::Runtime::Env).to receive(:personal_access_token).and_return(nil)
      end

      it 'returns a created token' do
        subject { described_class.new(user: { username: 'foo' }) }

        expect(subject).to receive(:create_personal_access_token).and_return('created_token')

        expect(subject.personal_access_token).to eq 'created_token'
      end
    end

    context 'when user is nil and QA::Runtime::Env.personal_access_token is nil' do
      before do
        allow(QA::Runtime::Env).to receive(:personal_access_token).and_return(nil)
      end

      it 'returns a created token' do
        client = described_class.new

        expect(client).to receive(:create_personal_access_token).and_return('created_token')

        expect(client.personal_access_token).to eq 'created_token'
      end
    end

    context 'when user is present and QA::Runtime::Env.personal_access_token is present' do
      before do
        allow(QA::Runtime::Env).to receive(:personal_access_token).and_return('a_token')
      end

      it 'returns a created token' do
        client = described_class.new(user: Struct.new(:username, :admin?).new('foo', false))

        expect(client).to receive(:create_personal_access_token).and_return('created_token')

        expect(client.personal_access_token).to eq 'created_token'
      end
    end
  end
end
