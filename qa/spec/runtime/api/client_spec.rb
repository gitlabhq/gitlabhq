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
    it 'returns specified token from env' do
      stub_env('PERSONAL_ACCESS_TOKEN', 'a_token')

      expect(described_class.new.get_personal_access_token).to eq 'a_token'
    end

    it 'returns a created token' do
      allow_any_instance_of(described_class)
        .to receive(:create_personal_access_token).and_return('created_token')

      expect(described_class.new.get_personal_access_token).to eq 'created_token'
    end
  end
end
