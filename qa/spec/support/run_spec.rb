# frozen_string_literal: true

RSpec.describe QA::Support::Run do
  let(:class_instance) { (Class.new { include QA::Support::Run }).new }
  let(:response) { 'successful response' }
  let(:command) { 'some command' }
  let(:expected_result) { described_class::Result.new("#{command} 2>&1", 0, response) }

  it 'runs successfully' do
    expect(Open3).to receive(:capture2e).and_return([+response, double(exitstatus: 0)])

    expect(class_instance.run(command)).to eq(expected_result)
  end

  it 'retries twice and succeeds the third time' do
    allow(Open3).to receive(:capture2e).and_return([+'', double(exitstatus: 1)]).twice
    allow(Open3).to receive(:capture2e).and_return([+response, double(exitstatus: 0)])

    expect(class_instance.run(command)).to eq(expected_result)
  end

  it 'raises an exception on 3rd failure' do
    allow(Open3).to receive(:capture2e).and_return([+'FAILURE', double(exitstatus: 1)]).thrice

    expect { class_instance.run(command) }.to raise_error(QA::Support::Run::CommandError, /The command .* failed \(1\) with the following output:\nFAILURE/)
  end

  it 'returns the error message in a non-zero response when raise_on_failure is false' do
    allow(Open3).to receive(:capture2e).and_return([+'FAILURE', double(exitstatus: 1)])

    expect(class_instance.run(command, raise_on_failure: false).response).to eql('FAILURE')
  end
end
