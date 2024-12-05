# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VsCode::Settings::SettingsFinder, feature_category: :web_ide do
  let_it_be(:user) { create(:user) }

  describe '#execute' do
    context 'when nil is passed in as the list of settings' do
      let(:finder) { described_class.new(current_user: user, setting_types: nil) }

      subject { finder.execute }

      context 'when user has no settings' do
        it 'returns an empty array' do
          expect(subject).to eq([])
        end
      end

      context 'when user has settings' do
        before do
          create(:vscode_setting, user: user)
        end

        it 'returns an array of settings' do
          expect(subject.length).to eq(1)
          expect(subject[0].user_id).to eq(user.id)
          expect(subject[0].setting_type).to eq('settings')
        end
      end
    end

    context 'when a list of settings is passed, filters by the setting' do
      let_it_be(:setting) { create(:vscode_setting, user: user) }

      context 'when user has no settings with that type' do
        it 'returns an empty array' do
          finder = described_class.new(current_user: user, setting_types: ['profile'])
          expect(finder.execute).to eq([])
        end
      end

      context 'when user does have settings with the type' do
        it 'returns the record when a single setting exists' do
          result = described_class.new(current_user: user, setting_types: ['settings']).execute
          expect(result.length).to eq(1)
          expect(result[0].user_id).to eq(user.id)
          expect(result[0].setting_type).to eq('settings')
        end

        it 'returns multiple records when more than one setting exists' do
          create(:vscode_setting, user: user, setting_type: 'globalState')

          result = described_class.new(current_user: user, setting_types: %w[settings globalState]).execute
          expect(result.length).to eq(2)
        end

        it 'returns correct extensions settings when settings_context_hash is passed' do
          settings_context_hash = '1234'
          create(:vscode_setting, user: user, setting_type: 'extensions', settings_context_hash: settings_context_hash)
          create(:vscode_setting, user: user, setting_type: 'extensions', settings_context_hash: '5678')
          result = described_class.new(current_user: user, setting_types: ['extensions'],
            settings_context_hash: settings_context_hash).execute
          expect(result.length).to eq(1)
          expect(result[0].user_id).to eq(user.id)
          expect(result[0].setting_type).to eq('extensions')
          expect(result[0].settings_context_hash).to eq(settings_context_hash)
        end
      end
    end
  end
end
