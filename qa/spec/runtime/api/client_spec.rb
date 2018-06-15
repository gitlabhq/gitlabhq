describe QA::Runtime::API::Client do
  include Support::StubENV

  describe 'initialization' do
    it 'defaults to :gitlab address' do
      expect(described_class.new.address).to eq :gitlab
    end

    it 'uses specified address' do
      client = described_class.new('http:///example.com')

      expect(client.address).to eq 'http:///example.com'
    end
  end

  describe '#get_personal_access_token' do
    context 'when QA::Runtime::Env.personal_access_token is present' do
      before do
        allow(QA::Runtime::Env).to receive(:personal_access_token).and_return('a_token')
      end

      it 'returns specified token from env' do
        expect(described_class.new.get_personal_access_token).to eq 'a_token'
      end
    end

    context 'when QA::Runtime::Env.personal_access_token is nil' do
      before do
        allow(QA::Runtime::Env).to receive(:personal_access_token).and_return(nil)
        allow_any_instance_of(described_class)
          .to receive(:create_personal_access_token).and_return('created_token')
      end

      it 'returns a created token' do
        expect(described_class.new.get_personal_access_token).to eq 'created_token'
      end
    end
  end
end
