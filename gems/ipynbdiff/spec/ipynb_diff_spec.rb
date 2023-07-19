# frozen_string_literal: true

require_relative 'test_helper'

describe IpynbDiff do
  def diff_signs(diff)
    diff.to_s(:text).scan(/.*\n/).map { |l| l[0] }.join('')
  end

  describe '.diff' do
    let(:from_path) { FROM_PATH }
    let(:to_path) { TO_PATH }
    let(:from) { File.read(from_path) }
    let(:to) { File.read(to_path) }
    let(:include_frontmatter) { false }
    let(:hide_images) { false }

    subject { described_class.diff(from, to, include_frontmatter: include_frontmatter, hide_images: hide_images) }

    context 'if preprocessing is active' do
      it { is_expected.not_to include('<td>') }
    end

    context 'when to is nil' do
      let(:to) { nil }
      let(:from_path) { test_case_input_path('only_md') }

      it 'all lines are removals' do
        expect(diff_signs(subject)).to eq('-----')
      end
    end

    context 'when from is nil' do
      let(:from) { nil }
      let(:to_path) { test_case_input_path('only_md') }

      it 'all lines are additions' do
        expect(diff_signs(subject)).to eq('+++++')
      end
    end

    context 'when include_frontmatter is true' do
      let(:include_frontmatter) { true }

      it 'shows changes metadata in the metadata' do
        expect(subject.to_s(:text)).to include('+    display_name: New Python 3 (ipykernel)')
      end
    end

    context 'when hide_images is true' do
      let(:hide_images) { true }

      it 'hides images' do
        expect(subject.to_s(:text)).to include('     [Hidden Image Output]')
      end
    end

    context 'when include_frontmatter is false' do
      it 'drops metadata from the diff' do
        expect(subject.to_s(:text)).not_to include('+    display_name: New Python 3 (ipykernel)')
      end
    end

    context 'when either notebook can not be processed' do
      using RSpec::Parameterized::TableSyntax

      where(:ctx, :from, :to) do
        'because from is invalid'                 | 'a' | nil
        'because from does not have the cell tag' | '{"metadata":[]}' | nil
        'because to is invalid'                   | nil | 'a'
        'because to does not have the cell tag'   | nil | '{"metadata":[]}'
      end

      with_them do
        it { is_expected.to be_nil }
      end
    end
  end

  describe '.transform' do
    let(:notebook) { FROM_IPYNB }
    let(:include_frontmatter) { false }
    let(:hide_images) { false }

    subject do
      described_class.transform(notebook,
        include_frontmatter: include_frontmatter,
        hide_images: hide_images)
    end

    describe 'error cases' do
      using RSpec::Parameterized::TableSyntax

      where(:ctx, :notebook) do
        'notebook is nil' | nil
        'notebook is invalid' | 'a'
        'notebook does not have cell' | '{"metadata":[]}'
      end

      with_them do
        it { is_expected.to be_nil }
      end
    end

    describe 'options' do
      context 'when include_frontmatter is false' do
        it { is_expected.not_to include('display_name: Python 3 (ipykernel)') }
      end

      context 'when include_frontmatter is true' do
        let(:include_frontmatter) { true }

        it { is_expected.to include('display_name: Python 3 (ipykernel)') }
      end

      context 'when hide_images is false' do
        it { is_expected.not_to include('[Hidden Image Output]') }
      end

      context 'when hide_images is true' do
        let(:hide_images) { true }

        it { is_expected.to include('    [Hidden Image Output]') }
      end
    end
  end
end
