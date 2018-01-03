require 'spec_helper'

describe 'mail_room.yml' do
  include StubENV

  let(:mailroom_config_path) { 'config/mail_room.yml' }
  let(:gitlab_config_path) { 'config/mail_room.yml' }
  let(:queues_config_path) { 'config/redis.queues.yml' }

  let(:configuration) do
    vars = {
      'MAIL_ROOM_GITLAB_CONFIG_FILE' => absolute_path(gitlab_config_path),
      'GITLAB_REDIS_QUEUES_CONFIG_FILE' => absolute_path(queues_config_path)
    }
    cmd = "puts ERB.new(File.read(#{absolute_path(mailroom_config_path).inspect})).result"

    output, status = Gitlab::Popen.popen(%W(ruby -rerb -e #{cmd}), absolute_path('config'), vars)
    raise "Error interpreting #{mailroom_config_path}: #{output}" unless status.zero?

    YAML.load(output)
  end

  before do
    stub_env('GITLAB_REDIS_QUEUES_CONFIG_FILE', absolute_path(queues_config_path))
    clear_queues_raw_config
  end

  after do
    clear_queues_raw_config
  end

  context 'when incoming email is disabled' do
    let(:gitlab_config_path) { 'spec/fixtures/config/mail_room_disabled.yml' }

    it 'contains no configuration' do
      expect(configuration[:mailboxes]).to be_nil
    end
  end

  context 'when incoming email is enabled' do
    let(:gitlab_config_path) { 'spec/fixtures/config/mail_room_enabled.yml' }
    let(:queues_config_path) { 'spec/fixtures/config/redis_queues_new_format_host.yml' }

    let(:gitlab_redis_queues) { Gitlab::Redis::Queues.new(Rails.env) }

    it 'contains the intended configuration' do
      expect(configuration[:mailboxes].length).to eq(1)
      mailbox = configuration[:mailboxes].first

      expect(mailbox[:host]).to eq('imap.gmail.com')
      expect(mailbox[:port]).to eq(993)
      expect(mailbox[:ssl]).to eq(true)
      expect(mailbox[:start_tls]).to eq(false)
      expect(mailbox[:email]).to eq('gitlab-incoming@gmail.com')
      expect(mailbox[:password]).to eq('[REDACTED]')
      expect(mailbox[:name]).to eq('inbox')
      expect(mailbox[:idle_timeout]).to eq(60)

      redis_url = gitlab_redis_queues.url
      sentinels = gitlab_redis_queues.sentinels

      expect(mailbox[:delivery_options][:redis_url]).to be_present
      expect(mailbox[:delivery_options][:redis_url]).to eq(redis_url)

      expect(mailbox[:delivery_options][:sentinels]).to be_present
      expect(mailbox[:delivery_options][:sentinels]).to eq(sentinels)

      expect(mailbox[:arbitration_options][:redis_url]).to be_present
      expect(mailbox[:arbitration_options][:redis_url]).to eq(redis_url)

      expect(mailbox[:arbitration_options][:sentinels]).to be_present
      expect(mailbox[:arbitration_options][:sentinels]).to eq(sentinels)
    end
  end

  def clear_queues_raw_config
    Gitlab::Redis::Queues.remove_instance_variable(:@_raw_config)
  rescue NameError
    # raised if @_raw_config was not set; ignore
  end

  def absolute_path(path)
    Rails.root.join(path).to_s
  end
end
