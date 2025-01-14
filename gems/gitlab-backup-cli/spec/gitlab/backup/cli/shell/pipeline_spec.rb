# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::Shell::Pipeline do
  let(:command) { Gitlab::Backup::Cli::Shell::Command }
  let(:printf_command) { command.new('printf "3\n2\n1"') }
  let(:sort_command) { command.new('sort') }
  let(:true_command) { command.new('true') }
  let(:false_command) { command.new('false') }
  let(:tmpdir) { Pathname.new(Dir.mktmpdir('pipeline', temp_path)) }
  let(:envdata) do
    { 'CUSTOM' => 'data' }
  end

  subject(:pipeline) { described_class }

  after do
    FileUtils.rm_rf(tmpdir)
  end

  it { respond_to :shell_commands }

  describe '#initialize' do
    it 'accepts a single argument' do
      expect { pipeline.new(printf_command) }.not_to raise_exception
    end

    it 'accepts multiple arguments' do
      expect { pipeline.new(printf_command, sort_command) }.not_to raise_exception
    end
  end

  describe '#run!' do
    it 'returns a Pipeline::Result' do
      result = pipeline.new(true_command, true_command).run!

      expect(result).to be_a(Gitlab::Backup::Cli::Shell::Pipeline::Result)
    end

    it 'sets env variables from provided commands as part of pipeline execution' do
      echo_command = command.new("echo \"variable value ${CUSTOM}\"", env: envdata)
      read_io, write_io = IO.pipe

      pipeline.new(true_command, echo_command).run!(output: write_io)
      write_io.close
      output = read_io.read.chomp
      read_io.close

      expect(output).to eq('variable value data')
    end

    context 'with Pipeline::Status' do
      it 'includes stderr from the executed pipeline' do
        expected_output = 'my custom error content'
        err_command = command.new("echo #{expected_output} > /dev/stderr")

        result = pipeline.new(err_command).run!

        expect(result.stderr.chomp).to eq(expected_output)
      end

      it 'includes a list of Process::Status from the executed pipeline' do
        result = pipeline.new(true_command, true_command).run!

        expect(result.status_list).to all be_a(Process::Status)
        expect(result.status_list).to all respond_to(:exited?, :termsig, :stopsig, :exitstatus, :success?, :pid)
      end

      it 'includes a list of Process::Status that handles exit signals' do
        result = pipeline.new(false_command, false_command).run!

        expect(result.status_list).to all satisfy { |status| !status.success? }
        expect(result.status_list).to all satisfy { |status| status.exitstatus == 1 }
      end
    end

    it 'accepts stdin and stdout redirection' do
      echo_command = command.new(%(ruby -e "print 'stdin is : ' + STDIN.readline"))
      input_r, input_w = IO.pipe
      input_w.sync = true
      input_w.print 'my custom content'
      input_w.close

      output_r, output_w = IO.pipe

      result = pipeline.new(echo_command).run!(input: input_r, output: output_w)

      input_r.close
      output_w.close
      output = output_r.read
      output_r.close

      expect(result.status_list.size).to eq(1)
      expect(result.status_list[0]).to be_success
      expect(output).to match(/stdin is : my custom content/)
    end

    it 'accepts input from a file' do
      input_file = tmpdir.join('input.txt')
      File.open(input_file, 'w+') do |file|
        file.write('file content goes here')
      end

      read_command = command.new('read content; echo ${content}')

      output_r, output_w = IO.pipe

      pipeline.new(read_command).run!(input: input_file, output: output_w)

      output_w.close
      output = output_r.read
      output_r.close

      expect(output).to match(/file content goes here/)
    end

    it 'accepts output to file' do
      echo_command = command.new("echo \"variable value ${CUSTOM}\"", env: envdata)
      output_file = tmpdir.join('output.txt')

      pipeline.new(true_command, echo_command).run!(output: output_file)

      expect(File.exist?(output_file)).to be_truthy
      expect(File.read(output_file)).to match('variable value data')
    end

    it 'accepts output to file with permissions in array format' do
      echo_command = command.new("echo \"variable value ${CUSTOM}\"", env: envdata)
      output_file = tmpdir.join('output.txt')

      pipeline.new(true_command, echo_command).run!(output: [output_file, 'w', 0o600])

      expect(File.exist?(output_file)).to be_truthy
      expect(File.read(output_file)).to match('variable value data')
    end
  end

  describe Gitlab::Backup::Cli::Shell::Pipeline::Result do
    describe '#success?' do
      context 'when one of multiple commands is unsuccessful' do
        it 'returns false' do
          expect(Gitlab::Backup::Cli::Shell::Pipeline.new(true_command, false_command).run!.success?).to be false
        end
      end

      context 'when all commands are successful' do
        it 'returns true' do
          expect(Gitlab::Backup::Cli::Shell::Pipeline.new(true_command, true_command).run!.success?).to be true
        end
      end

      context 'when there is no result' do
        let(:result) { described_class.new(status_list: nil) }

        it 'returns false' do
          expect(result.success?).to be false
        end
      end

      context 'when there is no status list' do
        let(:result) { described_class.new }

        it 'returns false' do
          expect(result.success?).to be false
        end
      end

      context 'when there are no status results' do
        let(:result) { described_class.new(status_list: []) }

        it 'returns false' do
          expect(result.success?).to be false
        end
      end
    end
  end
end
