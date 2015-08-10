require 'spec_helper'

describe BlobHelper do
  describe 'highlight' do
    let(:blob_name) { 'test.lisp' }
    let(:no_context_content) { ":type \"assem\"))" }
    let(:blob_content) { "(make-pathname :defaults name\n#{no_context_content}" }
    let(:split_content) { blob_content.split("\n") }
    let(:multiline_content) do
      %q(
      def test(input):
        """This is line 1 of a multi-line comment.
        This is line 2.
        """
      )
    end

    it 'should return plaintext for unknown lexer context' do
      result = highlight(blob_name, no_context_content, nowrap: true, continue: false)
      expect(result).to eq('<span id="LC1" class="line">:type &quot;assem&quot;))</span>')
    end

    it 'should highlight single block' do
      expected = %Q[<span id="LC1" class="line"><span class="p">(</span><span class="nb">make-pathname</span> <span class="ss">:defaults</span> <span class="nv">name</span></span>
<span id="LC2" class="line"><span class="ss">:type</span> <span class="s">&quot;assem&quot;</span><span class="p">))</span></span>]

      expect(highlight(blob_name, blob_content, nowrap: true, continue: false)).to eq(expected)
    end

    it 'should highlight continued blocks' do
      # Both lines have LC1 as ID since formatter doesn't support continue at the moment
      expected = [
        '<span id="LC1" class="line"><span class="p">(</span><span class="nb">make-pathname</span> <span class="ss">:defaults</span> <span class="nv">name</span></span>',
        '<span id="LC1" class="line"><span class="ss">:type</span> <span class="s">&quot;assem&quot;</span><span class="p">))</span></span>'
      ]

      result = split_content.map{ |content| highlight(blob_name, content, nowrap: true, continue: true) }
      expect(result).to eq(expected)
    end

    it 'should highlight multi-line comments' do
      result = highlight(blob_name, multiline_content, nowrap: true, continue: false)
      html = Nokogiri::HTML(result)
      lines = html.search('.s')
      expect(lines.count).to eq(3)
      expect(lines[0].text).to eq('"""This is line 1 of a multi-line comment.')
      expect(lines[1].text).to eq('        This is line 2.')
      expect(lines[2].text).to eq('        """')
    end

    context 'diff highlighting' do
      let(:blob_name) { 'test.diff' }
      let(:blob_content) { "+aaa\n+bbb\n- ccc\n ddd\n"}
      let(:expected) do
        %q(<span id="LC1" class="line"><span class="gi">+aaa</span></span>
<span id="LC2" class="line"><span class="gi">+bbb</span></span>
<span id="LC3" class="line"><span class="gd">- ccc</span></span>
<span id="LC4" class="line"> ddd</span>)
      end

      it 'should highlight each line properly' do
        result = highlight(blob_name, blob_content, nowrap: true, continue: false)
        expect(result).to eq(expected)
      end
    end
  end
end
