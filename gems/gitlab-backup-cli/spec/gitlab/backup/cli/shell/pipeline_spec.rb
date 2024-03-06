# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Backup::Cli::Shell::Pipeline do
  let(:command) { Gitlab::Backup::Cli::Shell::Command }
  let(:printf_command) { command.new('printf "3\n2\n1"') }
  let(:sort_command) { command.new('sort') }

  subject(:pipeline) { described_class }

  it { respond_to :shell_commands }

  describe '#initialize' do
    it 'accepts a single argument' do
      expect { pipeline.new(printf_command) }.not_to raise_exception
    end

    it 'accepts multiple arguments' do
      expect { pipeline.new(printf_command, sort_command) }.not_to raise_exception
    end
  end

  describe '#run_pipeline!' do
    it 'returns a Pipeline::Status' do
      true_command = command.new('true')

      result = pipeline.new(true_command, true_command).run_pipeline!

      expect(result).to be_a(Gitlab::Backup::Cli::Shell::Pipeline::Result)
    end

    context 'with Pipeline::Status' do
      it 'includes stderr from the executed pipeline' do
        expected_output = 'my custom error content'
        err_command = command.new("echo #{expected_output} > /dev/stderr")

        result = pipeline.new(err_command).run_pipeline!

        expect(result.stderr.chomp).to eq(expected_output)
      end

      it 'includes a list of Process::Status from the executed pipeline' do
        true_command = command.new('true')

        result = pipeline.new(true_command, true_command).run_pipeline!

        expect(result.status_list).to all be_a(Process::Status)
        expect(result.status_list).to all respond_to(:exited?, :termsig, :stopsig, :exitstatus, :success?, :pid)
      end

      it 'includes a list of Process::Status that handles exit signals' do
        false_command = command.new('false')

        result = pipeline.new(false_command, false_command).run_pipeline!

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

      result = pipeline.new(echo_command).run_pipeline!(input: input_r, output: output_w)

      input_r.close
      output_w.close
      output = output_r.read
      output_r.close

      expect(result.status_list.size).to eq(1)
      expect(result.status_list[0]).to be_success
      expect(output).to match(/stdin is : my custom content/)
    end
  end
end
