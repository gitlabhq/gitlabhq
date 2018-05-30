describe QA::Runtime::Env do
  include Support::StubENV

  describe '.user_type' do
    it 'returns standard if not defined' do
      expect(described_class.user_type).to eq('standard')
    end

    it 'returns standard as defined' do
      stub_env('GITLAB_USER_TYPE', 'standard')
      expect(described_class.user_type).to eq('standard')
    end

    it 'returns ldap as defined' do
      stub_env('GITLAB_USER_TYPE', 'ldap')
      expect(described_class.user_type).to eq('ldap')
    end

    it 'returns an error if invalid user type' do
      stub_env('GITLAB_USER_TYPE', 'foobar')
      expect { described_class.user_type }.to raise_error(ArgumentError)
    end
  end
end
