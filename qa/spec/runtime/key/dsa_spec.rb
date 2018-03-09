describe QA::Runtime::Key::DSA do
  describe '#public_key' do
    subject { described_class.new.public_key }

    it 'generates a public DSA key' do
      expect(subject).to match(%r{\Assh\-dss AAAA[0-9A-Za-z+/]+={0,3}})
    end
  end
end
