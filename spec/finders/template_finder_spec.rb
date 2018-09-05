require 'spec_helper'

describe TemplateFinder do
  using RSpec::Parameterized::TableSyntax

  describe '#build' do
    where(:type, :expected_class) do
      :dockerfiles    | described_class
      :gitignores     | described_class
      :gitlab_ci_ymls | described_class
      :licenses       | ::LicenseTemplateFinder
    end

    with_them do
      subject { described_class.build(type) }

      it { is_expected.to be_a(expected_class) }
    end
  end

  describe '#execute' do
    where(:type, :vendored_name) do
      :dockerfiles    | 'Binary'
      :gitignores     | 'Actionscript'
      :gitlab_ci_ymls | 'Android'
    end

    with_them do
      it 'returns all vendored templates when no name is specified' do
        result = described_class.new(type).execute

        expect(result).to include(have_attributes(name: vendored_name))
      end

      it 'returns only the specified vendored template when a name is specified' do
        result = described_class.new(type, name: vendored_name).execute

        expect(result).to have_attributes(name: vendored_name)
      end

      it 'returns nil when an unknown name is specified' do
        result = described_class.new(type, name: 'unknown').execute

        expect(result).to be_nil
      end
    end
  end
end
