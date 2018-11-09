# frozen_string_literal: true

describe QA::Resource::Repository::Push do
  describe '.files=' do
    let(:files) do
      [
        {
          name: 'file.txt',
          content: 'foo'
        }
      ]
    end

    it 'raises an error if files is not an array' do
      expect { subject.files = '' }.to raise_error(ArgumentError)
    end

    it 'raises an error if files is an empty array' do
      expect { subject.files = [] }.to raise_error(ArgumentError)
    end

    it 'does not raise if files is an array' do
      expect { subject.files = files }.not_to raise_error
    end
  end
end
