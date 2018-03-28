require 'spec_helper'

describe AppearancesHelper do
  describe '#header_message' do
    it 'returns nil when header message field is not set' do
      appearance = create(:appearance)

      expect(helper.header_message).to be_nil
    end

    context 'when header message is set' do
      it 'includes current message' do
        message = "Foo bar"
        appearance = create(:appearance, header_message: message)

        expect(helper.header_message).to include(message)
      end
    end
  end

  describe '#footer_message' do
    it 'returns nil when footer message field is not set' do
      appearance = create(:appearance)

      expect(helper.footer_message).to be_nil
    end

    context 'when footer message is set' do
      it 'includes current message' do
        message = "Foo bar"
        appearance = create(:appearance, footer_message: message)

        expect(helper.footer_message).to include(message)
      end
    end
  end
end
