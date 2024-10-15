# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli do
  subject(:cli) { described_class }

  around do |example|
    previous_title = get_process_title
    example.run
    Process.setproctitle(previous_title)
  end

  it "has a version number" do
    expect(Gitlab::Backup::Cli::VERSION).not_to be nil
  end

  describe '.start' do
    it 'sets the process title', :silence_output do
      cli.start([])

      expect(get_process_title).to eq('gitlab-backup-cli')
    end

    it 'delegates to Runner.start' do
      argv = ['version']

      expect(Gitlab::Backup::Cli::Runner).to receive(:start).with(argv)

      cli.start(argv)
    end
  end

  describe '.update_process_title!' do
    context 'without any parameters' do
      it 'sets a process title to `gitlab-backup-cli`' do
        cli.update_process_title!

        expect(get_process_title).to eq('gitlab-backup-cli')
      end
    end

    context 'with parameters' do
      it 'sets a process title to `gitlab-backup-cli: ` including provided content' do
        cli.update_process_title!('context info')

        expect(get_process_title).to eq('gitlab-backup-cli: context info')
      end
    end
  end

  def get_process_title
    ps = `ps -p #{Process.pid} -o command`
    ps.split("\n").last.strip
  end
end
