# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LicenseTemplateFinder do
  describe '#execute' do
    subject(:result) { described_class.new(nil, params).execute }

    let(:categories) { categorised_licenses.keys }
    let(:categorised_licenses) { result.group_by(&:category) }

    context 'popular: true' do
      let(:params) { { popular: true } }

      it 'only returns popular licenses' do
        expect(categories).to contain_exactly(:Popular)
        expect(categorised_licenses[:Popular]).to be_present
      end
    end

    context 'popular: false' do
      let(:params) { { popular: false } }

      it 'only returns unpopular licenses' do
        expect(categories).to contain_exactly(:Other)
        expect(categorised_licenses[:Other]).to be_present
      end
    end

    context 'popular: nil' do
      let(:params) { { popular: nil } }

      it 'returns all licenses known by the Licensee gem' do
        from_licensee = Licensee::License.all.map { |l| l.key }

        expect(result.map(&:key)).to match_array(from_licensee)
      end

      it 'correctly copies all attributes' do
        licensee = Licensee::License.all.first
        found = result.find { |r| r.key == licensee.key }

        aggregate_failures do
          %i[key name content nickname url meta featured?].each do |k|
            expect(found.public_send(k)).to eq(licensee.public_send(k))
          end
        end
      end
    end
  end
end
