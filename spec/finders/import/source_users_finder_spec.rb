# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUsersFinder, feature_category: :importers do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:import_source_users) { create_list(:import_source_user, 3, namespace: group) }

  describe '#execute' do
    subject(:source_user_result) { described_class.new(group, user).execute }

    context 'when user is authorized to read the import source users' do
      before do
        stub_member_access_level(group, owner: user)
      end

      it 'returns all import source users' do
        expect(source_user_result).to match_array(import_source_users)
      end
    end

    context 'when user is not authorized to read the import source users' do
      before do
        stub_member_access_level(group, maintainer: user)
      end

      it 'is empty' do
        expect(source_user_result).to be_empty
      end
    end
  end
end
