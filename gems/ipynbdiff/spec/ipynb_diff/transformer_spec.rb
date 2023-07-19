# frozen_string_literal: true

require_relative '../test_helper'

describe IpynbDiff::Transformer do
  describe '.transform' do
    using RSpec::Parameterized::TableSyntax

    let!(:default_config) { { include_frontmatter: false, hide_images: false } }

    let(:test_case) { read_test_case(test_case_name) }
    let(:notebook) { test_case[:input] || FROM_IPYNB }
    let(:config) { {} }

    subject { described_class.new(**default_config.merge(config)).transform(notebook) }

    where(:ctx, :test_case_name, :config) do
      'renders metadata' | 'no_cells' | { include_frontmatter: true }
      'is empty for no cells, but metadata is false' | 'no_cells_no_metadata' | {}
      'adds markdown cell' | 'only_md' | {}
      'adds block with only one line of markdown' | 'single_line_md' | {}
      'adds raw block' | 'only_raw' | {}
      'code cell, but no output' | 'only_code' | {}
      'code cell, but no language' | 'only_code_no_language' | {}
      'code cell, but no kernelspec' | 'only_code_no_kernelspec' | {}
      'code cell, but no nb metadata' | 'only_code_no_metadata' | {}
      'text output' | 'text_output' | {}
      'ignores html output' | 'ignore_html_output' | {}
      'extracts png output along with text' | 'text_png_output' | {}
      'embeds svg as image' | 'svg' | {}
      'extracts latex output' | 'latex_output'  | {}
      'extracts error output' | 'error_output'  | {}
      'does not fetch tags if there is no cell metadata' | 'no_metadata_on_cell' | {}
      'generates :percent decorator' | 'percent_decorator' | {}
      'parses stream output' | 'stream_text' | {}
      'ignores unknown output type' | 'unknown_output_type' | {}
      'handles backslash correctly' | 'backslash_as_last_char' | {}
      'multiline png output' | 'multiline_png_output' | {}
      'hides images when option passed' | 'hide_images' | { hide_images: true }
      '\n within source lines' | 'source_with_linebreak' | { hide_images: true }
    end

    with_them do
      it 'generates the expected markdown' do
        expect(subject.as_text).to eq test_case[:expected_markdown]
      end

      it 'marks the lines correctly' do
        blocks = subject.blocks.map { |b| b[:source_symbol] }.join("\n")

        expect(blocks).to eq test_case[:expected_symbols]
      end
    end

    describe 'Source line map' do
      let(:config) { { include_frontmatter: false } }
      let(:test_case_name) { 'text_png_output' }

      it 'generates the correct transformed to source line map' do
        line_numbers = subject.blocks.map { |b| b[:source_line] }.join("\n")

        expect(line_numbers).to eq test_case[:expected_line_numbers]
      end
    end

    context 'when json is invalid' do
      let(:notebook) { 'a' }

      it 'raises error' do
        expect { subject }.to raise_error(IpynbDiff::InvalidNotebookError)
      end
    end

    context 'when it does not have the cell tag' do
      let(:notebook) { '{"metadata":[]}' }

      it 'raises error' do
        expect { subject }.to raise_error(IpynbDiff::InvalidNotebookError)
      end
    end

    context 'when notebook can not be parsed' do
      let(:notebook) { '{"cells":[]}' }

      before do
        allow(Oj::Parser.usual).to receive(:parse).and_return(nil)
      end

      it 'raises error' do
        expect { subject }.to raise_error(IpynbDiff::InvalidNotebookError)
      end
    end
  end
end
