# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('config', 'object_store_settings.rb')

RSpec.describe ObjectStoreSettings do
  describe '#parse!' do
    let(:settings) { Settingslogic.new(config) }

    subject { described_class.new(settings).parse! }

    context 'with valid config' do
      let(:connection) do
        {
          'provider' => 'AWS',
          'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
          'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY',
          'region' => 'us-east-1'
        }
      end

      let(:config) do
        {
          'lfs' => { 'enabled' => true },
          'artifacts' => { 'enabled' => true },
          'external_diffs' => { 'enabled' => false },
          'pages' => { 'enabled' => true },
          'object_store' => {
            'enabled' => true,
            'connection' => connection,
            'proxy_download' => true,
            'objects' => {
              'artifacts' => {
                'bucket' => 'artifacts',
                'proxy_download' => false
              },
              'lfs' => {
                'bucket' => 'lfs-objects'
              },
              'external_diffs' => {
                'bucket' => 'external_diffs',
                'enabled' => false
              },
              'pages' => {
                'bucket' => 'pages'
              }
            }
          }
        }
      end

      it 'sets correct default values' do
        subject

        expect(settings.artifacts['enabled']).to be true
        expect(settings.artifacts['object_store']['enabled']).to be true
        expect(settings.artifacts['object_store']['connection']).to eq(connection)
        expect(settings.artifacts['object_store']['direct_upload']).to be true
        expect(settings.artifacts['object_store']['background_upload']).to be false
        expect(settings.artifacts['object_store']['proxy_download']).to be false
        expect(settings.artifacts['object_store']['remote_directory']).to eq('artifacts')
        expect(settings.artifacts['object_store']['consolidated_settings']).to be true

        expect(settings.lfs['enabled']).to be true
        expect(settings.lfs['object_store']['enabled']).to be true
        expect(settings.lfs['object_store']['connection']).to eq(connection)
        expect(settings.lfs['object_store']['direct_upload']).to be true
        expect(settings.lfs['object_store']['background_upload']).to be false
        expect(settings.lfs['object_store']['proxy_download']).to be true
        expect(settings.lfs['object_store']['remote_directory']).to eq('lfs-objects')
        expect(settings.lfs['object_store']['consolidated_settings']).to be true

        expect(settings.pages['enabled']).to be true
        expect(settings.pages['object_store']['enabled']).to be true
        expect(settings.pages['object_store']['connection']).to eq(connection)
        expect(settings.pages['object_store']['remote_directory']).to eq('pages')
        expect(settings.pages['object_store']['consolidated_settings']).to be true

        expect(settings.external_diffs['enabled']).to be false
        expect(settings.external_diffs['object_store']['enabled']).to be false
        expect(settings.external_diffs['object_store']['remote_directory']).to eq('external_diffs')
        expect(settings.external_diffs['object_store']['consolidated_settings']).to be true
      end

      it 'raises an error when a bucket is missing' do
        config['object_store']['objects']['lfs'].delete('bucket')

        expect { subject }.to raise_error(/Object storage for lfs must have a bucket specified/)
      end

      it 'does not raise error if pages bucket is missing' do
        config['object_store']['objects']['pages'].delete('bucket')

        expect { subject }.not_to raise_error
      end

      it 'allows pages to define its own connection' do
        pages_connection = { 'provider' => 'Google', 'google_application_default' => true }
        config['pages'] = {
          'enabled' => true,
          'object_store' => {
            'enabled' => true,
            'connection' => pages_connection
          }
        }

        expect { subject }.not_to raise_error

        described_class::WORKHORSE_ACCELERATED_TYPES.each do |object_type|
          section = settings.try(object_type)

          next unless section

          expect(section['object_store']['connection']).to eq(connection)
          expect(section['object_store']['consolidated_settings']).to be true
        end

        expect(settings.pages['object_store']['connection']).to eq(pages_connection)
        expect(settings.pages['object_store']['consolidated_settings']).to be_falsey
      end

      context 'with legacy config' do
        let(:legacy_settings) do
          {
            'enabled' => true,
            'remote_directory' => 'some-bucket',
            'direct_upload' => true,
            'background_upload' => false,
            'proxy_download' => false
          }
        end

        before do
          settings.lfs['object_store'] = described_class.legacy_parse(legacy_settings)
        end

        it 'does not alter config if legacy settings are specified' do
          subject

          expect(settings.artifacts['object_store']).to be_nil
          expect(settings.lfs['object_store']['remote_directory']).to eq('some-bucket')
          expect(settings.external_diffs['object_store']).to be_nil
        end
      end
    end
  end

  describe '.legacy_parse' do
    it 'sets correct default values' do
      settings = described_class.legacy_parse(nil)

      expect(settings['enabled']).to be false
      expect(settings['direct_upload']).to be false
      expect(settings['background_upload']).to be true
      expect(settings['remote_directory']).to be nil
    end

    it 'respects original values' do
      original_settings = Settingslogic.new({
        'enabled' => true,
        'remote_directory' => 'artifacts'
      })

      settings = described_class.legacy_parse(original_settings)

      expect(settings['enabled']).to be true
      expect(settings['direct_upload']).to be false
      expect(settings['background_upload']).to be true
      expect(settings['remote_directory']).to eq 'artifacts'
    end
  end
end
