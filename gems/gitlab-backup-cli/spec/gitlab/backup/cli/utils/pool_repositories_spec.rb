# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::Utils::PoolRepositories do
  let(:context) { build_test_context }

  subject(:pool) { described_class.new(gitlab_basepath: context.gitlab_basepath) }

  describe '#gitlab_basepath' do
    it 'returns a path' do
      expect(pool.gitlab_basepath).to be_a(Pathname)
      expect(pool.gitlab_basepath).to eq(context.gitlab_basepath)
    end
  end

  describe '#reinitialize!' do
    let(:json_output) do
      [
        %q({"disk_path":"aa/bb/repo1.git","status":"scheduled","error_message":null}),
        %q({"disk_path":"cc/dd/repo2.git","status":"skipped","error_message":null}),
        %q({"disk_path":"ee/ff/repo3.git","status":"failed","error_message":"Error message"})
      ]
    end

    it 'output parsed content and output to terminal' do
      fake_output = json_output.map { |json| { stream: :stdout, output: json } }
      fake_rake = FakeRake.new(fake_output: fake_output)
      expect(pool).to receive(:build_reset_task).and_return(fake_rake)

      timestamp_pattern = /\[[\d\- :]+UTC\]/

      expected_stdout = /
        #{timestamp_pattern}#{Regexp.escape(' ℹ️  Reinitializing object pools...')}\n
        #{timestamp_pattern}#{Regexp.escape(' ✅️  Object pool aa/bb/repo1.git...')}\n
        #{timestamp_pattern}#{Regexp.escape(' ℹ️  Object pool cc/dd/repo2.git... [SKIPPED]')}\n
        #{timestamp_pattern}#{Regexp.escape(' ℹ️  Object pool ee/ff/repo3.git... [FAILED]')}\n
      /mx

      expected_stderr = /
        #{timestamp_pattern}#{Regexp.escape(' ❌️  Object pool ee/ff/repo3.git failed to reset (Error message)')}\n
      /mx

      expect { pool.reinitialize! }.to output(expected_stdout).to_stdout.and output(expected_stderr).to_stderr
    end

    it 'handles content not in json format and output to terminal' do
      fake_output = [
        { stream: :stdout, output: 'stdout content not in JSON format' },
        { stream: :stderr, output: 'stderr content not in JSON format' }
      ]
      fake_rake = FakeRake.new(fake_output: fake_output)
      expect(pool).to receive(:build_reset_task).and_return(fake_rake)

      timestamp_pattern = /\[[\d\- :]+UTC\]/

      expected_stdout = /
        #{timestamp_pattern}#{Regexp.escape(' ℹ️  Reinitializing object pools...')}\n
      /mx

      expected_stderr = /
        #{timestamp_pattern}#{Regexp.escape(' ⚠️  Failed to parse: stdout content not in JSON format')}\n
        #{timestamp_pattern}#{Regexp.escape(' ⚠️  stderr content not in JSON format')}\n
      /mx

      expect { pool.reinitialize! }.to output(expected_stdout).to_stdout.and output(expected_stderr).to_stderr
    end
  end
end
