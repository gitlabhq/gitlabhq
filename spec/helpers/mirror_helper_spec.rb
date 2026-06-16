# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MirrorHelper, feature_category: :source_code_management do
  describe '#remote_mirrors_table_data' do
    let(:remote_mirror) do
      build_stubbed(:remote_mirror,
        url: 'https://user:pass@example.com/mirror.git',
        enabled: true,
        last_update_started_at: Time.zone.parse('2024-01-01 00:00:00'),
        last_update_at: Time.zone.parse('2024-01-01 00:00:00'),
        last_error: nil,
        update_status: 'finished')
    end

    subject(:result) { Gitlab::Json.safe_parse(helper.remote_mirrors_table_data([remote_mirror])) }

    before do
      allow(remote_mirror).to receive_messages(
        safe_url: 'https://user:*****@example.com/mirror.git',
        ssh_key_auth?: false,
        ssh_public_key: nil
      )
      allow(remote_mirror).to receive(:read_attribute).with(:enabled).and_return(true)
    end

    it 'returns serialized mirror data' do
      mirror_data = result.first

      expect(mirror_data['id']).to eq(remote_mirror.id)
      expect(mirror_data['enabled']).to be(true)
      expect(mirror_data['url']).to eq('https://user:*****@example.com/mirror.git')
      expect(mirror_data['direction']).to eq('push')
      expect(mirror_data['last_update_started_at']).to eq('2024-01-01T00:00:00Z')
      expect(mirror_data['last_update_at']).to eq('2024-01-01T00:00:00Z')
      expect(mirror_data['last_error']).to be_nil
      expect(mirror_data['update_status']).to eq('finished')
      expect(mirror_data['ssh_key_auth']).to be(false)
      expect(mirror_data['ssh_public_key']).to be_nil
    end

    it 'does not include EE-only mirror branch keys in CE', unless: Gitlab.ee? do
      mirror_data = result.first

      expect(mirror_data).not_to have_key('mirror_branches_setting')
      expect(mirror_data).not_to have_key('mirror_branch_regex')
    end

    context 'when mirror has an error' do
      before do
        allow(remote_mirror).to receive(:last_error).and_return(" Connection refused \n")
      end

      it 'strips the error message' do
        expect(result.first['last_error']).to eq('Connection refused')
      end
    end

    context 'when safe_url is nil' do
      before do
        allow(remote_mirror).to receive(:safe_url).and_return(nil)
      end

      it 'returns nil for the url field' do
        expect(result.first['url']).to be_nil
      end
    end

    context 'when timestamps are nil' do
      let(:mirror_without_timestamps) do
        build_stubbed(:remote_mirror,
          url: 'https://example.com/no-ts.git',
          enabled: true,
          last_update_started_at: nil,
          last_update_at: nil)
      end

      subject(:result) { Gitlab::Json.safe_parse(helper.remote_mirrors_table_data([mirror_without_timestamps])) }

      before do
        allow(mirror_without_timestamps).to receive_messages(
          safe_url: 'https://example.com/no-ts.git',
          ssh_key_auth?: false,
          ssh_public_key: nil
        )
        allow(mirror_without_timestamps).to receive(:read_attribute).with(:enabled).and_return(true)
      end

      it 'returns nil for timestamp fields' do
        mirror_data = result.first

        expect(mirror_data['last_update_started_at']).to be_nil
        expect(mirror_data['last_update_at']).to be_nil
      end
    end
  end
end
