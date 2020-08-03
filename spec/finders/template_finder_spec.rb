# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TemplateFinder do
  using RSpec::Parameterized::TableSyntax

  describe '#build' do
    let(:project) { build_stubbed(:project) }

    where(:type, :expected_class) do
      :dockerfiles    | described_class
      :gitignores     | described_class
      :gitlab_ci_ymls | described_class
      :licenses | ::LicenseTemplateFinder
      :metrics_dashboard_ymls | described_class
    end

    with_them do
      subject(:finder) { described_class.build(type, project) }

      it { is_expected.to be_a(expected_class) }
      it { expect(finder.project).to eq(project) }
    end
  end

  describe '#execute' do
    where(:type, :vendored_name) do
      :dockerfiles    | 'Binary'
      :gitignores     | 'Actionscript'
      :gitlab_ci_ymls | 'Android'
      :metrics_dashboard_ymls | 'Default'
    end

    with_them do
      it 'returns all vendored templates when no name is specified' do
        result = described_class.new(type, nil).execute

        expect(result).to include(have_attributes(name: vendored_name))
      end

      it 'returns only the specified vendored template when a name is specified' do
        result = described_class.new(type, nil, name: vendored_name).execute

        expect(result).to have_attributes(name: vendored_name)
      end

      it 'returns nil when an unknown name is specified' do
        result = described_class.new(type, nil, name: 'unknown').execute

        expect(result).to be_nil
      end
    end
  end
end
