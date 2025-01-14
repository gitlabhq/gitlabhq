# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::Shell::Command do
  let(:tmpdir) { Pathname.new(Dir.mktmpdir('command', temp_path)) }
  let(:envdata) do
    { 'CUSTOM' => 'data' }
  end

  subject(:command) { described_class }

  after do
    FileUtils.remove_entry(tmpdir)
  end

  describe '#initialize' do
    it 'accepts required attributes' do
      expect { command.new('ls', '-l') }.not_to raise_exception
    end

    it 'accepts optional attributes' do
      expect { command.new('ls', '-l', env: envdata) }.not_to raise_exception
    end
  end

  describe '#cmd_args' do
    let(:cmd_args) { %w[ls -l] }

    it 'returns a list of command args' do
      cmd = command.new(*cmd_args)

      expect(cmd.cmd_args).to eq(cmd_args)
    end

    context 'when with_env is true' do
      it 'returns the same list of command args when no env is provided' do
        cmd = command.new(*cmd_args)

        expect(cmd.cmd_args(with_env: true)).to eq(cmd_args)
      end

      it 'returns a list of command args with the env hash as its first element' do
        cmd = command.new(*cmd_args, env: envdata)

        result = cmd.cmd_args(with_env: true)

        expect(result.first).to eq(envdata)
        expect(result[1..]).to eq(cmd_args)
      end
    end
  end

  describe '#capture' do
    it 'returns stdout from executed command' do
      expected_output = 'my custom content'

      result = command.new('echo', expected_output).capture

      expect(result.stdout.chomp).to eq(expected_output)
      expect(result.stderr).to be_empty
    end

    it 'returns stderr from executed command' do
      expected_output = 'my custom error content'

      result = command.new('sh', '-c', "echo #{expected_output} > /dev/stderr").capture

      expect(result.stdout).to be_empty
      expect(result.stderr.chomp).to eq(expected_output)
    end

    it 'returns a Process::Status from the executed command' do
      result = command.new('pwd').capture

      expect(result.status).to be_a(Process::Status)
      expect(result.status).to respond_to(:exited?, :termsig, :stopsig, :exitstatus, :success?, :pid)
    end

    it 'returns the execution duration' do
      result = command.new('sleep 0.1').capture

      expect(result.duration).to be > 0.1
    end

    it 'sets the provided env variables as part of process execution' do
      result = command.new("echo \"variable value ${CUSTOM}\"", env: envdata).capture

      expect(result.stdout.chomp).to eq('variable value data')
    end
  end

  describe '#run_single_pipeline!' do
    it 'runs without any exceptions' do
      expect { command.new('true').run_single_pipeline! }.not_to raise_exception
    end

    it 'sets env variables from provided commands as part of pipeline execution' do
      echo_command = command.new("echo \"variable value ${CUSTOM}\"", env: envdata)
      read_io, write_io = IO.pipe

      echo_command.run_single_pipeline!(output: write_io)
      write_io.close
      output = read_io.read.chomp
      read_io.close

      expect(output).to eq('variable value data')
    end

    it 'accepts stdin and stdout redirection' do
      echo_command = command.new(%(ruby -e "print 'stdin is : ' + STDIN.readline"))
      input_r, input_w = IO.pipe
      input_w.sync = true
      input_w.print 'my custom content'
      input_w.close

      output_r, output_w = IO.pipe

      result = echo_command.run_single_pipeline!(input: input_r, output: output_w)

      input_r.close
      output_w.close
      output = output_r.read
      output_r.close

      expect(result.status).to be_success
      expect(output).to match(/stdin is : my custom content/)
    end

    it 'accepts input from a file' do
      input_file = tmpdir.join('input.txt')
      File.open(input_file, 'w+') do |file|
        file.write('file content goes here')
      end

      read_command = command.new('read content; echo ${content}')

      output_r, output_w = IO.pipe

      read_command.run_single_pipeline!(input: input_file, output: output_w)

      output_w.close
      output = output_r.read
      output_r.close

      expect(output).to match(/file content goes here/)
    end

    it 'accepts output to file' do
      echo_command = command.new("echo \"variable value ${CUSTOM}\"", env: envdata)
      output_file = tmpdir.join('output.txt')

      echo_command.run_single_pipeline!(output: output_file)

      expect(File.exist?(output_file)).to be_truthy
      expect(File.read(output_file)).to match('variable value data')
    end

    it 'accepts output to file with permissions in array format' do
      echo_command = command.new("echo \"variable value ${CUSTOM}\"", env: envdata)
      output_file = tmpdir.join('output.txt')

      echo_command.run_single_pipeline!(output: [output_file, 'w', 0o600])

      expect(File.exist?(output_file)).to be_truthy
      expect(File.read(output_file)).to match('variable value data')
    end

    it 'returns a Command::SinglePipelineResult' do
      result = command.new('true').run_single_pipeline!

      expect(result).to be_a(Gitlab::Backup::Cli::Shell::Command::SinglePipelineResult)
    end

    context 'with Pipeline::Status' do
      it 'includes stderr from the executed pipeline' do
        expected_output = 'my custom error content'
        err_command = command.new("echo #{expected_output} > /dev/stderr")

        result = err_command.run_single_pipeline!

        expect(result.stderr.chomp).to eq(expected_output)
      end

      it 'executed pipelines returns a Process::Status in the status field' do
        result = command.new('true').run_single_pipeline!

        expect(result.status).to be_a(Process::Status)
        expect(result.status).to respond_to(:exited?, :termsig, :stopsig, :exitstatus, :success?, :pid)
      end

      it 'includes a list of Process::Status that handles exit signals' do
        result = command.new('false').run_single_pipeline!

        expect(result.status).to satisfy { |status| !status.success? }
        expect(result.status).to satisfy { |status| status.exitstatus == 1 }
      end
    end
  end
end
