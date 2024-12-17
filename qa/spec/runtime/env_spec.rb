# frozen_string_literal: true

RSpec.describe QA::Runtime::Env do
  include QA::Support::Helpers::StubEnv

  shared_examples 'boolean method' do |**kwargs|
    it_behaves_like 'boolean method with parameter', kwargs
  end

  shared_examples 'boolean method with parameter' do |method:, env_key:, default:, param: nil|
    context 'when there is an env variable set' do
      it 'returns false when variable is falsey or unsupported' do
        stub_env(env_key, 'false')
        expect(described_class.public_send(method, *param)).to eq(false)

        stub_env(env_key, 'no')
        expect(described_class.public_send(method, *param)).to eq(false)

        stub_env(env_key, '0')
        expect(described_class.public_send(method, *param)).to eq(false)

        stub_env(env_key, 'anything')
        expect(described_class.public_send(method, *param)).to eq(false)
      end

      it 'returns true when variable set to truthy' do
        stub_env(env_key, 'true')
        expect(described_class.public_send(method, *param)).to eq(true)

        stub_env(env_key, '1')
        expect(described_class.public_send(method, *param)).to eq(true)

        stub_env(env_key, 'yes')
        expect(described_class.public_send(method, *param)).to eq(true)
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

  describe '.webdriver_headless?' do
    it_behaves_like 'boolean method',
      method: :webdriver_headless?,
      env_key: 'WEBDRIVER_HEADLESS',
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

  describe '.running_on_dot_com?' do
    using RSpec::Parameterized::TableSyntax

    where(:url, :result) do
      'https://www.gitlab.com'     | true
      'https://staging.gitlab.com' | true
      'http://www.gitlab.com'      | true
      'http://localhost:3000'      | false
      'http://localhost'           | false
      'http://gdk.test:3000'       | false
    end

    with_them do
      before do
        described_class.instance_variable_set(:@gitlab_host, nil)
        QA::Runtime::Scenario.define(:gitlab_address, url)
      end

      it { expect(described_class.running_on_dot_com?).to eq result }
    end
  end

  describe '.running_on_dev?' do
    using RSpec::Parameterized::TableSyntax

    where(:url, :result) do
      'https://www.gitlab.com' | false
      'http://localhost:3000'  | true
      'http://localhost'       | false
      'http://gdk.test:3000'   | true
    end

    with_them do
      before do
        described_class.instance_variable_set(:@gitlab_host, nil)
        QA::Runtime::Scenario.define(:gitlab_address, url)
      end

      it { expect(described_class.running_on_dev?).to eq result }
    end
  end

  describe '.github_access_token' do
    it 'returns "" if QA_GITHUB_ACCESS_TOKEN is not defined' do
      stub_env('QA_GITHUB_ACCESS_TOKEN', nil)

      expect(described_class.github_access_token).to eq('')
    end

    it 'returns stripped string if QA_GITHUB_ACCESS_TOKEN is defined' do
      stub_env('QA_GITHUB_ACCESS_TOKEN', ' abc123 ')
      expect(described_class.github_access_token).to eq('abc123')
    end
  end

  describe '.knapsack?' do
    before do
      stub_env('CI_NODE_TOTAL', '2')
    end

    it 'returns true if running in parallel CI run' do
      expect(described_class.knapsack?).to be_truthy
    end

    it 'returns false if knapsack disabled' do
      stub_env('NO_KNAPSACK', 'true')
      expect(described_class.knapsack?).to be_falsey
    end

    it 'returns false if not running in a parallel job' do
      stub_env('CI_NODE_TOTAL', '1')

      expect(described_class.knapsack?).to be_falsey
    end

    it 'returns false if not running in ci' do
      stub_env('CI_NODE_TOTAL', nil)

      expect(described_class.knapsack?).to be_falsey
    end
  end

  describe '.require_github_access_token!' do
    it 'raises ArgumentError if QA_GITHUB_ACCESS_TOKEN is not defined' do
      stub_env('QA_GITHUB_ACCESS_TOKEN', nil)

      expect { described_class.require_github_access_token! }.to raise_error(ArgumentError)
    end

    it 'does not raise if QA_GITHUB_ACCESS_TOKEN is defined' do
      stub_env('QA_GITHUB_ACCESS_TOKEN', ' abc123 ')

      expect { described_class.require_github_access_token! }.not_to raise_error
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

    it_behaves_like 'boolean method with parameter',
      method: :can_test?,
      param: :praefect,
      env_key: 'QA_CAN_TEST_PRAEFECT',
      default: true

    it 'raises ArgumentError if feature is unknown' do
      expect { described_class.can_test? :foo }.to raise_error(ArgumentError, 'Unknown feature "foo"')
    end
  end

  describe 'remote grid credentials' do
    before do
      stub_env('QA_REMOTE_GRID_USERNAME', nil)
      stub_env('QA_REMOTE_GRID_ACCESS_KEY', nil)
      stub_env('QA_REMOTE_GRID', nil)
    end

    it 'is blank if username is empty' do
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

    describe '.remote_grid_protocol' do
      it 'defaults protocol to http' do
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

  describe '.canary_cookie' do
    subject { described_class.canary_cookie }

    context 'with QA_COOKIES set' do
      using RSpec::Parameterized::TableSyntax

      where(:cookie_value, :result) do
        'gitlab_canary=true'                      | { gitlab_canary: "true" }
        'other_cookie=value\;gitlab_canary=true'  | { gitlab_canary: "true" }
        'gitlab_canary=false'                     | { gitlab_canary: "false" }
        'gitlab_canary=false\;other_cookie=value' | { gitlab_canary: "false" }
      end

      with_them do
        before do
          stub_env('QA_COOKIES', cookie_value)
        end

        it { is_expected.to eq(result) }
      end
    end

    context 'without QA_COOKIES set' do
      before do
        stub_env('QA_COOKIES', nil)
      end

      it { is_expected.to be_empty }
    end
  end
end
