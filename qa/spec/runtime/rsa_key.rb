describe QA::Runtime::RSAKey do
  describe '#public_key' do
    subject { described_class.new.public_key }

    it 'generates a public RSA key' do
      expect(subject).to match(%r{\Assh\-rsa AAAA[0-9A-Za-z+/]+={0,3}\z})
    end
  end
end
