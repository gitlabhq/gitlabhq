# frozen_string_literal: true

describe QA::Runtime::Env do
  include Helpers::StubENV

  shared_examples 'boolean method' do |**kwargs|
    it_behaves_like 'boolean method with parameter', kwargs
  end

  shared_examples 'boolean method with parameter' do |method:, param: nil, env_key:, default:|
    context 'when there is an env variable set' do
      it 'returns false when falsey values specified' do
        stub_env(env_key, 'false')
        expect(described_class.public_send(method, *param)).to be_falsey

        stub_env(env_key, 'no')
        expect(described_class.public_send(method, *param)).to be_falsey

        stub_env(env_key, '0')
        expect(described_class.public_send(method, *param)).to be_falsey
      end

      it 'returns true when anything else specified' do
        stub_env(env_key, 'true')
        expect(described_class.public_send(method, *param)).to be_truthy

        stub_env(env_key, '1')
        expect(described_class.public_send(method, *param)).to be_truthy

        stub_env(env_key, 'anything')
        expect(described_class.public_send(method, *param)).to be_truthy
      end
    end

    context 'when there is no env variable set' do
      it "returns the default, #{default}" do
        stub_env(env_key, nil)
        expect(described_class.public_send(method, *param)).to be(default)
      end
    end
  end

  describe '.signup_disabled?' do
    it_behaves_like 'boolean method',
      method: :signup_disabled?,
      env_key: 'SIGNUP_DISABLED',
      default: false
  end

  describe '.debug?' do
    it_behaves_like 'boolean method',
      method: :debug?,
      env_key: 'QA_DEBUG',
      default: false
  end

  describe '.chrome_headless?' do
    it_behaves_like 'boolean method',
      method: :chrome_headless?,
      env_key: 'CHROME_HEADLESS',
      default: true
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

  describe '.personal_access_token' do
    around do |example|
      described_class.instance_variable_set(:@personal_access_token, nil)
      example.run
      described_class.instance_variable_set(:@personal_access_token, nil)
    end

    context 'when GITLAB_QA_ACCESS_TOKEN is set' do
      before do
        stub_env('GITLAB_QA_ACCESS_TOKEN', 'a_token_too')
      end

      it 'returns specified token from env' do
        expect(described_class.personal_access_token).to eq 'a_token_too'
      end
    end

    context 'when @personal_access_token is set' do
      before do
        described_class.personal_access_token = 'another_token'
      end

      it 'returns the instance variable value' do
        expect(described_class.personal_access_token).to eq 'another_token'
      end
    end
  end

  describe '.personal_access_token=' do
    around do |example|
      described_class.instance_variable_set(:@personal_access_token, nil)
      example.run
      described_class.instance_variable_set(:@personal_access_token, nil)
    end

    it 'saves the token' do
      described_class.personal_access_token = 'a_token'

      expect(described_class.personal_access_token).to eq 'a_token'
    end
  end

  describe '.forker?' do
    before do
      stub_env('GITLAB_FORKER_USERNAME', nil)
      stub_env('GITLAB_FORKER_PASSWORD', nil)
    end

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

  describe '.knapsack?' do
    it 'returns true if KNAPSACK_GENERATE_REPORT is defined' do
      stub_env('KNAPSACK_GENERATE_REPORT', 'true')

      expect(described_class.knapsack?).to be_truthy
    end

    it 'returns true if KNAPSACK_REPORT_PATH is defined' do
      stub_env('KNAPSACK_REPORT_PATH', '/a/path')

      expect(described_class.knapsack?).to be_truthy
    end

    it 'returns true if KNAPSACK_TEST_FILE_PATTERN is defined' do
      stub_env('KNAPSACK_TEST_FILE_PATTERN', '/a/**/pattern')

      expect(described_class.knapsack?).to be_truthy
    end

    it 'returns false if neither KNAPSACK_GENERATE_REPORT nor KNAPSACK_REPORT_PATH nor KNAPSACK_TEST_FILE_PATTERN are defined' do
      expect(described_class.knapsack?).to be_falsey
    end
  end

  describe '.knapsack?' do
    it 'returns true if KNAPSACK_GENERATE_REPORT is defined' do
      stub_env('KNAPSACK_GENERATE_REPORT', 'true')

      expect(described_class.knapsack?).to be_truthy
    end

    it 'returns true if KNAPSACK_REPORT_PATH is defined' do
      stub_env('KNAPSACK_REPORT_PATH', '/a/path')

      expect(described_class.knapsack?).to be_truthy
    end

    it 'returns true if KNAPSACK_TEST_FILE_PATTERN is defined' do
      stub_env('KNAPSACK_TEST_FILE_PATTERN', '/a/**/pattern')

      expect(described_class.knapsack?).to be_truthy
    end

    it 'returns false if neither KNAPSACK_GENERATE_REPORT nor KNAPSACK_REPORT_PATH nor KNAPSACK_TEST_FILE_PATTERN are defined' do
      expect(described_class.knapsack?).to be_falsey
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

  describe '.require_admin_access_token!' do
    it 'raises ArgumentError if GITLAB_QA_ADMIN_ACCESS_TOKEN is not specified' do
      stub_env('GITLAB_QA_ADMIN_ACCESS_TOKEN', nil)

      expect { described_class.require_admin_access_token! }.to raise_error(ArgumentError)
    end

    it 'does not raise exception if GITLAB_QA_ADMIN_ACCESS_TOKEN is specified' do
      stub_env('GITLAB_QA_ADMIN_ACCESS_TOKEN', 'foobar123')

      expect { described_class.require_admin_access_token! }.not_to raise_error
    end
  end

  describe '.log_destination' do
    it 'returns $stdout if QA_LOG_PATH is not defined' do
      stub_env('QA_LOG_PATH', nil)

      expect(described_class.log_destination).to eq($stdout)
    end

    it 'returns the path if QA_LOG_PATH is defined' do
      stub_env('QA_LOG_PATH', 'path/to_file')

      expect(described_class.log_destination).to eq('path/to_file')
    end
  end

  describe '.can_test?' do
    it_behaves_like 'boolean method with parameter',
      method: :can_test?,
      param: :git_protocol_v2,
      env_key: 'QA_CAN_TEST_GIT_PROTOCOL_V2',
      default: true

    it_behaves_like 'boolean method with parameter',
      method: :can_test?,
      param: :admin,
      env_key: 'QA_CAN_TEST_ADMIN_FEATURES',
      default: true

    it 'raises ArgumentError if feature is unknown' do
      expect { described_class.can_test? :foo }.to raise_error(ArgumentError, 'Unknown feature "foo"')
    end
  end

  describe 'remote grid credentials' do
    it 'is blank if username is empty' do
      stub_env('QA_REMOTE_GRID_USERNAME', nil)

      expect(described_class.send(:remote_grid_credentials)).to eq('')
    end

    it 'throws ArgumentError if GRID_ACCESS_KEY is not specified with USERNAME' do
      stub_env('QA_REMOTE_GRID_USERNAME', 'foo')

      expect { described_class.send(:remote_grid_credentials) }.to raise_error(ArgumentError, 'Please provide an access key for user "foo"')
    end

    it 'returns a user:key@ combination when all args are satiated' do
      stub_env('QA_REMOTE_GRID_USERNAME', 'foo')
      stub_env('QA_REMOTE_GRID_ACCESS_KEY', 'bar')

      expect(described_class.send(:remote_grid_credentials)).to eq('foo:bar@')
    end
  end

  describe '.remote_grid_protocol' do
    it 'defaults protocol to http' do
      stub_env('QA_REMOTE_GRID_PROTOCOL', nil)
      expect(described_class.remote_grid_protocol).to eq('http')
    end
  end

  describe '.remote_grid' do
    it 'is falsey if QA_REMOTE_GRID is not set' do
      expect(described_class.remote_grid).to be_falsey
    end

    it 'accepts https protocol' do
      stub_env('QA_REMOTE_GRID', 'localhost:4444')
      stub_env('QA_REMOTE_GRID_PROTOCOL', 'https')

      expect(described_class.remote_grid).to eq('https://localhost:4444/wd/hub')
    end

    context 'with credentials' do
      it 'has a grid of http://user:key@grid/wd/hub' do
        stub_env('QA_REMOTE_GRID_USERNAME', 'foo')
        stub_env('QA_REMOTE_GRID_ACCESS_KEY', 'bar')
        stub_env('QA_REMOTE_GRID', 'localhost:4444')

        expect(described_class.remote_grid).to eq('http://foo:bar@localhost:4444/wd/hub')
      end
    end

    context 'without credentials' do
      it 'has a grid of http://grid/wd/hub' do
        stub_env('QA_REMOTE_GRID', 'localhost:4444')

        expect(described_class.remote_grid).to eq('http://localhost:4444/wd/hub')
      end
    end
  end
end
