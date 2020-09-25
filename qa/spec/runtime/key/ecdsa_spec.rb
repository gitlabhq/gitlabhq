# frozen_string_literal: true

RSpec.describe QA::Runtime::Key::ECDSA do
  describe '#public_key' do
    [256, 384, 521].each do |bits|
      it "generates a public #{bits}-bits ECDSA key" do
        subject = described_class.new(bits).public_key

        expect(subject).to match(%r{\Aecdsa\-sha2\-\w+ AAAA[0-9A-Za-z+/]+={0,3}})
      end
    end
  end

  describe '#new' do
    it 'does not support arbitrary bits' do
      expect { described_class.new(123) }
        .to raise_error(QA::Service::Shellout::CommandError)
    end
  end
end
