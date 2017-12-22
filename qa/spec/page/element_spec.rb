describe QA::Page::Element do
  context 'when pattern is an expression' do
    subject { described_class.new(:something, /button 'Sign in'/) }

    it 'is correctly matches against a string' do
      expect(subject.matches?("button 'Sign in'")).to be true
    end

    it 'does not match if string does not match against a pattern' do
      expect(subject.matches?("button 'Sign out'")).to be false
    end
  end

  context 'when pattern is a string' do
    subject { described_class.new(:something, 'button') }

    it 'is correctly matches against a string' do
      expect(subject.matches?('some button in the view')).to be true
    end

    it 'does not match if string does not match against a pattern' do
      expect(subject.matches?('text_field :name')).to be false
    end
  end

  context 'when pattern is not supported' do
    subject { described_class.new(:something, [/something/]) }

    it 'raises an error' do
      expect { subject.matches?('some line') }
        .to raise_error ArgumentError
    end
  end
end
