# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'mail_room.yml', feature_category: :service_desk do
  include StubENV

  let(:mailroom_config_path) { 'config/mail_room.yml' }
  let(:gitlab_config_path) { 'config/mail_room.yml' }
  let(:queues_config_path) { 'config/redis.queues.yml' }

  let(:configuration) { YAML.safe_load(ERB.new(File.read(mailroom_config_path)).result, permitted_classes: [Symbol]) }

  before do
    stub_env('MAIL_ROOM_GITLAB_CONFIG_FILE', absolute_path(gitlab_config_path))
    allow(Gitlab::Redis::Queues).to receive(:config_file_name).and_return(queues_config_path)
    Gitlab::MailRoom.instance_variable_set(:@enabled_configs, nil)
    Gitlab::MailRoom.instance_variable_set(:@yaml, nil)
  end

  context 'when incoming email is disabled' do
    let(:gitlab_config_path) { 'spec/fixtures/config/mail_room_disabled.yml' }

    it 'contains no configuration' do
      expect(configuration[:mailboxes]).to be_nil
    end
  end

  context 'when both incoming email and service desk email are enabled' do
    let(:gitlab_config_path) { 'spec/fixtures/config/mail_room_enabled.yml' }
    let(:queues_config_path) { 'spec/fixtures/config/redis_new_format_host.yml' }
    let(:gitlab_redis_queues) { Gitlab::Redis::Queues.new(Rails.env) }

    it 'contains the intended configuration' do
      expected_mailbox = {
        host: 'imap.gmail.com',
        port: 993,
        ssl: true,
        start_tls: false,
        email: 'gitlab-incoming@gmail.com',
        password: '[REDACTED]',
        name: 'inbox',
        idle_timeout: 60,
        delete_after_delivery: true,
        expunge_deleted: true
      }
      expected_options = {
        redis_url: gitlab_redis_queues.url,
        sentinels: gitlab_redis_queues.sentinels
      }

      expect(configuration[:mailboxes].length).to eq(2)
      expect(configuration[:mailboxes]).to all(include(expected_mailbox))
      expect(configuration[:mailboxes].map { |m| m[:delivery_options] }).to all(include(expected_options))
      expect(configuration[:mailboxes].map { |m| m[:arbitration_options] }).to all(include(expected_options))
    end
  end

  context 'when both incoming email and service desk email are enabled for Microsoft Graph' do
    let(:gitlab_config_path) { 'spec/fixtures/config/mail_room_enabled_ms_graph.yml' }
    let(:queues_config_path) { 'spec/fixtures/config/redis_new_format_host.yml' }
    let(:gitlab_redis_queues) { Gitlab::Redis::Queues.new(Rails.env) }

    it 'contains the intended configuration' do
      expected_mailbox = {
        email: 'gitlab-incoming@gmail.com',
        name: 'inbox',
        idle_timeout: 60,
        delete_after_delivery: false
      }
      expected_options = {
        redis_url: gitlab_redis_queues.url,
        sentinels: gitlab_redis_queues.sentinels
      }
      expected_inbox_options = {
        tenant_id: '12345',
        client_id: 'MY-CLIENT-ID',
        client_secret: 'MY-CLIENT-SECRET',
        poll_interval: 60
      }

      expect(configuration[:mailboxes].length).to eq(2)
      expect(configuration[:mailboxes]).to all(include(expected_mailbox))
      expect(configuration[:mailboxes].map { |m| m[:inbox_method] }).to all(eq('microsoft_graph'))
      expect(configuration[:mailboxes].map { |m| m[:inbox_options] }).to all(eq(expected_inbox_options))
      expect(configuration[:mailboxes].map { |m| m[:delivery_options] }).to all(include(expected_options))
      expect(configuration[:mailboxes].map { |m| m[:delivery_options] }).to all(include(expected_options))
      expect(configuration[:mailboxes].map { |m| m[:arbitration_options] }).to all(include(expected_options))
    end
  end

  def absolute_path(path)
    Rails.root.join(path).to_s
  end
end
