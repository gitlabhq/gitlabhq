# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationsFinder do
  let(:application1) { create(:application, name: 'some_application', owner: nil, redirect_uri: 'http://some_application.url', scopes: '') }
  let(:application2) { create(:application, name: 'another_application', owner: nil, redirect_uri: 'http://other_application.url', scopes: '') }
  let(:user_application) { create(:application, name: 'user_application', owner: create(:user), redirect_uri: 'http://user_application.url', scopes: '') }
  let(:group_application) { create(:application, name: 'group_application', owner: create(:group), redirect_uri: 'http://group_application.url', scopes: '') }

  describe '#execute' do
    it 'returns an array of instance applications' do
      found = described_class.new.execute

      expect(found).to match_array([application1, application2])
    end

    context 'by_id' do
      context 'with existing id' do
        it 'returns the application' do
          params = { id: application1.id }
          found = described_class.new(params).execute

          expect(found).to match(application1)
        end
      end

      context 'with invalid id' do
        it 'returns nil for user application' do
          params = { id: user_application.id }
          found = described_class.new(params).execute

          expect(found).to be_nil
        end

        it 'returns nil for group application' do
          params = { id: group_application.id }
          found = described_class.new(params).execute

          expect(found).to be_nil
        end

        it 'returns nil for non-existing application' do
          params = { id: non_existing_record_id }
          found = described_class.new(params).execute

          expect(found).to be_nil
        end
      end
    end
  end
end
