# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationsFinder do
  let(:application1) { create(:application, name: 'some_application', owner: nil, redirect_uri: 'http://some_application.url', scopes: '') }
  let(:application2) { create(:application, name: 'another_application', owner: nil, redirect_uri: 'http://other_application.url', scopes: '') }

  describe '#execute' do
    it 'returns an array of applications' do
      found = described_class.new.execute

      expect(found).to match_array([application1, application2])
    end
    it 'returns the application by id' do
      params = { id: application1.id }
      found = described_class.new(params).execute

      expect(found).to match(application1)
    end
  end
end
