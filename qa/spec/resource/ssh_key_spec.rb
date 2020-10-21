# frozen_string_literal: true

RSpec.describe QA::Resource::SSHKey do
  describe '#key' do
    it 'generates a default key' do
      expect(subject.key).to be_a(QA::Runtime::Key::RSA)
    end
  end

  describe '#title' do
    it 'generates a default title' do
      expect(subject.title).to match(/E2E test key: \d+/)
    end

    it 'is possible to set the title' do
      subject.title = 'I am in a title'

      expect(subject.title).to eq('E2E test key: I am in a title')
    end
  end
end
