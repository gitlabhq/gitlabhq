# frozen_string_literal: true

describe QA::Specs::ParallelRunner do
  include Helpers::StubENV

  before do
    allow(QA::Runtime::Scenario).to receive(:attributes).and_return(parallel: true)
    stub_env('GITLAB_QA_ACCESS_TOKEN', 'skip_token_creation')
  end

  it 'passes args to parallel_tests' do
    expect_cli_arguments(['--tag', '~orchestrated', *QA::Specs::Runner::DEFAULT_TEST_PATH_ARGS])

    subject.run(['--tag', '~orchestrated', *QA::Specs::Runner::DEFAULT_TEST_PATH_ARGS])
  end

  it 'passes a given test path to parallel_tests and adds a separator' do
    expect_cli_arguments(%w[-- qa/specs/features/foo])

    subject.run(%w[qa/specs/features/foo])
  end

  it 'passes tags and test paths to parallel_tests and adds a separator' do
    expect_cli_arguments(%w[--tag smoke -- qa/specs/features/foo qa/specs/features/bar])

    subject.run(%w[--tag smoke qa/specs/features/foo qa/specs/features/bar])
  end

  it 'passes tags and test paths with separators to parallel_tests' do
    expect_cli_arguments(%w[-- --tag smoke -- qa/specs/features/foo qa/specs/features/bar])

    subject.run(%w[-- --tag smoke -- qa/specs/features/foo qa/specs/features/bar])
  end

  it 'passes supported environment variables' do
    # Test only env vars starting with GITLAB because some of the others
    # affect how the runner behaves, and we're not concerned with those
    # behaviors in this test
    gitlab_env_vars = QA::Runtime::Env::ENV_VARIABLES.reject { |v| !v.start_with?('GITLAB') }

    gitlab_env_vars.each do |k, v|
      stub_env(k, v)
    end

    gitlab_env_vars['QA_RUNTIME_SCENARIO_ATTRIBUTES'] = '{"parallel":true}'

    expect_cli_arguments([], gitlab_env_vars)

    subject.run([])
  end

  def expect_cli_arguments(arguments, env = { 'QA_RUNTIME_SCENARIO_ATTRIBUTES' => '{"parallel":true}' })
    cmd = "bundle exec parallel_test -t rspec --combine-stderr --serialize-stdout -- #{arguments.join(' ')}"
    expect(Open3).to receive(:popen2e)
      .with(hash_including(env), cmd)
      .and_return(0)
  end
end
