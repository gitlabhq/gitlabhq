require 'spec_helper'

describe 'bin/storage_check' do
  it 'is executable' do
    command = %w[bin/storage_check -t unix://the/path/to/a/unix-socket.sock -i 10 -d]
    expected_output = 'Checking unix://the/path/to/a/unix-socket.sock every 10 seconds'

    output, status = Gitlab::Popen.popen(command, Rails.root.to_s)

    expect(status).to eq(0)
    expect(output).to include(expected_output)
  end
end
