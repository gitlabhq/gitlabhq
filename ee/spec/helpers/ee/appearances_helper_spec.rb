require 'spec_helper'

describe AppearancesHelper do
  describe '#header_message' do
    it 'returns nil when header message field is not set' do
      appearance = build(:appearance)

      expect(helper.header_message(appearance)).to be_nil
    end

    context 'when header message is set' do
      let(:appearance) { build(:appearance, header_message: message) }

      it 'includes current message' do
        message = "Foo bar"
        appearance = build(:appearance, header_message: message)

        expect(helper.header_message(appearance)).to include(message)
      end
    end
  end

  describe '#footer_message' do
    it 'returns nil when footer message field is not set' do
      appearance = build(:appearance)

      expect(helper.footer_message(appearance)).to be_nil
    end

    context 'when footer message is set' do
      let(:appearance) { build(:appearance, header_message: message) }

      it 'includes current message' do
        message = "Foo bar"
        appearance = build(:appearance, footer_message: message)

        expect(helper.footer_message(appearance)).to include(message)
      end
    end
  end
end
