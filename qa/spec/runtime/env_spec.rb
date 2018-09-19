describe QA::Runtime::Env do
  include Support::StubENV

  describe '.chrome_headless?' do
    context 'when there is an env variable set' do
      it 'returns false when falsey values specified' do
        stub_env('CHROME_HEADLESS', 'false')
        expect(described_class.chrome_headless?).to be_falsey

        stub_env('CHROME_HEADLESS', 'no')
        expect(described_class.chrome_headless?).to be_falsey

        stub_env('CHROME_HEADLESS', '0')
        expect(described_class.chrome_headless?).to be_falsey
      end

      it 'returns true when anything else specified' do
        stub_env('CHROME_HEADLESS', 'true')
        expect(described_class.chrome_headless?).to be_truthy

        stub_env('CHROME_HEADLESS', '1')
        expect(described_class.chrome_headless?).to be_truthy

        stub_env('CHROME_HEADLESS', 'anything')
        expect(described_class.chrome_headless?).to be_truthy
      end
    end

    context 'when there is no env variable set' do
      it 'returns the default, true' do
        stub_env('CHROME_HEADLESS', nil)
        expect(described_class.chrome_headless?).to be_truthy
      end
    end
  end

  describe '.running_in_ci?' do
    context 'when there is an env variable set' do
      it 'returns true if CI' do
        stub_env('CI', 'anything')
        expect(described_class.running_in_ci?).to be_truthy
      end

      it 'returns true if CI_SERVER' do
        stub_env('CI_SERVER', 'anything')
        expect(described_class.running_in_ci?).to be_truthy
      end
    end

    context 'when there is no env variable set' do
      it 'returns true' do
        stub_env('CI', nil)
        stub_env('CI_SERVER', nil)
        expect(described_class.running_in_ci?).to be_falsey
      end
    end
  end

  describe '.forker?' do
    it 'returns false if no forker credentials are defined' do
      expect(described_class).not_to be_forker
    end

    it 'returns false if only forker username is defined' do
      stub_env('GITLAB_FORKER_USERNAME', 'foo')

      expect(described_class).not_to be_forker
    end

    it 'returns false if only forker password is defined' do
      stub_env('GITLAB_FORKER_PASSWORD', 'bar')

      expect(described_class).not_to be_forker
    end

    it 'returns true if forker username and password are defined' do
      stub_env('GITLAB_FORKER_USERNAME', 'foo')
      stub_env('GITLAB_FORKER_PASSWORD', 'bar')

      expect(described_class).to be_forker
    end
  end

  describe '.github_access_token' do
    it 'returns "" if GITHUB_ACCESS_TOKEN is not defined' do
      stub_env('GITHUB_ACCESS_TOKEN', nil)

      expect(described_class.github_access_token).to eq('')
    end

    it 'returns stripped string if GITHUB_ACCESS_TOKEN is defined' do
      stub_env('GITHUB_ACCESS_TOKEN', ' abc123 ')
      expect(described_class.github_access_token).to eq('abc123')
    end
  end

  describe '.require_github_access_token!' do
    it 'raises ArgumentError if GITHUB_ACCESS_TOKEN is not defined' do
      stub_env('GITHUB_ACCESS_TOKEN', nil)

      expect { described_class.require_github_access_token! }.to raise_error(ArgumentError)
    end

    it 'does not raise if GITHUB_ACCESS_TOKEN is defined' do
      stub_env('GITHUB_ACCESS_TOKEN', ' abc123 ')

      expect { described_class.require_github_access_token! }.not_to raise_error
    end
  end
end
