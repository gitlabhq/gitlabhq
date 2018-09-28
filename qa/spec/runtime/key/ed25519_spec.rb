describe QA::Runtime::Key::ED25519 do
  describe '#public_key' do
    subject { described_class.new.public_key }

    it 'generates a public ED25519 key' do
      expect(subject).to match(%r{\Assh\-ed25519 AAAA[0-9A-Za-z+/]})
    end
  end
end
