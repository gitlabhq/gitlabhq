require 'spec_helper'

describe BlobHelper do
  include TreeHelper

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

  describe '#highlight' do
    it 'returns plaintext for unknown lexer context' do
      result = helper.highlight(blob_name, no_context_content)
      expect(result).to eq(%[<pre class="code highlight"><code><span id="LC1" class="line">:type "assem"))</span></code></pre>])
    end

    it 'highlights single block' do
      expected = %Q[<pre class="code highlight"><code><span id="LC1" class="line"><span class="p">(</span><span class="nb">make-pathname</span> <span class="ss">:defaults</span> <span class="nv">name</span></span>
<span id="LC2" class="line"><span class="ss">:type</span> <span class="s">"assem"</span><span class="p">))</span></span></code></pre>]

      expect(helper.highlight(blob_name, blob_content)).to eq(expected)
    end

    it 'highlights multi-line comments' do
      result = helper.highlight(blob_name, multiline_content)
      html = Nokogiri::HTML(result)
      lines = html.search('.s')
      expect(lines.count).to eq(3)
      expect(lines[0].text).to eq('"""This is line 1 of a multi-line comment.')
      expect(lines[1].text).to eq('      This is line 2.')
      expect(lines[2].text).to eq('      """')
    end

    context 'diff highlighting' do
      let(:blob_name) { 'test.diff' }
      let(:blob_content) { "+aaa\n+bbb\n- ccc\n ddd\n"}
      let(:expected) do
        %q(<pre class="code highlight"><code><span id="LC1" class="line"><span class="gi">+aaa</span></span>
<span id="LC2" class="line"><span class="gi">+bbb</span></span>
<span id="LC3" class="line"><span class="gd">- ccc</span></span>
<span id="LC4" class="line"> ddd</span></code></pre>)
      end

      it 'highlights each line properly' do
        result = helper.highlight(blob_name, blob_content)
        expect(result).to eq(expected)
      end
    end
  end

  describe "#sanitize_svg" do
    let(:input_svg_path) { File.join(Rails.root, 'spec', 'fixtures', 'unsanitized.svg') }
    let(:data) { open(input_svg_path).read }
    let(:expected_svg_path) { File.join(Rails.root, 'spec', 'fixtures', 'sanitized.svg') }
    let(:expected) { open(expected_svg_path).read }

    it 'retains essential elements' do
      blob = OpenStruct.new(data: data)
      expect(sanitize_svg(blob).data).to eq(expected)
    end
  end

  describe '#parse_csv' do
    it 'parses CSV data' do
      expect { |block| parse_csv("foo,bar\noof,rab", &block) }
        .to yield_successive_args(%w(foo bar), %w(oof rab))
    end

    it 'passes options to CSV.parse' do
      options = { foo: :foo, bar: :bar }

      expect(CSV).to receive(:parse).with(anything, options)

      parse_csv('foo', options)
    end

    it 'rescues MalformedCSVError' do
      expect(CSV).to receive(:parse).and_raise(CSV::MalformedCSVError)

      expect { parse_csv('') }.not_to raise_error
    end
  end

  describe "#edit_blob_link" do
    let(:namespace) { create(:namespace, name: 'gitlab' )}
    let(:project) { create(:project, namespace: namespace) }

    before do
      allow(self).to receive(:current_user).and_return(double)
      allow(self).to receive(:can_collaborate_with_project?).and_return(true)
    end

    it 'verifies blob is text' do
      expect(helper).not_to receive(:blob_text_viewable?)

      button = edit_blob_link(project, 'refs/heads/master', 'README.md')

      expect(button).to start_with('<button')
    end

    it 'uses the passed blob instead retrieve from repository' do
      blob = project.repository.blob_at('refs/heads/master', 'README.md')

      expect(project.repository).not_to receive(:blob_at)

      edit_blob_link(project, 'refs/heads/master', 'README.md', blob: blob)
    end

    it 'returns a link with the proper route' do
      link = edit_blob_link(project, 'master', 'README.md')

      expect(Capybara.string(link).find_link('Edit')[:href]).to eq('/gitlab/gitlabhq/edit/master/README.md')
    end

    it 'returns a link with the passed link_opts on the expected route' do
      link = edit_blob_link(project, 'master', 'README.md', link_opts: { mr_id: 10 })

      expect(Capybara.string(link).find_link('Edit')[:href]).to eq('/gitlab/gitlabhq/edit/master/README.md?mr_id=10')
    end
  end
end
