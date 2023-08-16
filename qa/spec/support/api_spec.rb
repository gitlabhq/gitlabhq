# frozen_string_literal: true

module QA
  RSpec.describe QA::Support::API do
    describe ".masked_parsed_response" do
      let(:response) { Struct.new(:body).new('{ "secret": "foobar", "name": "gitlab" }') }

      it 'calls Masker to mask secrets' do
        expect(QA::Support::Helpers::Masker).to receive(:mask)
          .with(
            JSON.parse(response.body, symbolize_names: true),
            by_key: [:secret]
          )

        described_class.masked_parsed_response(response, mask_by_key: [:secret])
      end

      it 'accepts a single secret key' do
        expect(QA::Support::Helpers::Masker).to receive(:mask)
          .with(
            JSON.parse(response.body, symbolize_names: true),
            by_key: ['secret']
          )

        described_class.masked_parsed_response(response, mask_by_key: 'secret')
      end
    end
  end
end
