require 'spec_helper'

describe 'bin/sidekiq-cluster' do
  it 'runs successfully', :aggregate_failures do
    cmd = %w[bin/sidekiq-cluster --dryrun --negate cronjob]

    output, status = Gitlab::Popen.popen(cmd, Rails.root.to_s)

    expect(status).to be(0)
    expect(output).to include('"bundle", "exec", "sidekiq"')
    expect(output).not_to include('-qcronjob,1')
    expect(output).to include('-qdefault,1')
  end
end
