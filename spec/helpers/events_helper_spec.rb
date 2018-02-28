require 'spec_helper'

describe EventsHelper do
  describe '#event_note' do
    let(:user) { build(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'displays one line of plain text without alteration' do
      input = 'A short, plain note'
      expect(helper.event_note(input)).to match(input)
      expect(helper.event_note(input)).not_to match(/\.\.\.\z/)
    end

    it 'displays inline code' do
      input = 'A note with `inline code`'
      expected = 'A note with <code>inline code</code>'

      expect(helper.event_note(input)).to match(expected)
    end

    it 'truncates a note with multiple paragraphs' do
      input = "Paragraph 1\n\nParagraph 2"
      expected = 'Paragraph 1...'

      expect(helper.event_note(input)).to match(expected)
    end

    it 'displays the first line of a code block' do
      input = "```\nCode block\nwith two lines\n```"
      expected = %r{<pre.+><code><span class="line">Code block\.\.\.</span>\n</code></pre>}

      expect(helper.event_note(input)).to match(expected)
    end

    it 'truncates a single long line of text' do
      text = 'The quick brown fox jumped over the lazy dog twice' # 50 chars
      input = text * 4
      expected = (text * 2).sub(/.{3}/, '...')

      expect(helper.event_note(input)).to match(expected)
    end

    it 'preserves a link href when link text is truncated' do
      text = 'The quick brown fox jumped over the lazy dog' # 44 chars
      input = "#{text}#{text}#{text} " # 133 chars
      link_url = 'http://example.com/foo/bar/baz' # 30 chars
      input << link_url
      expected_link_text = 'http://example...</a>'

      expect(helper.event_note(input)).to match(link_url)
      expect(helper.event_note(input)).to match(expected_link_text)
    end

    it 'preserves code color scheme' do
      input = "```ruby\ndef test\n  'hello world'\nend\n```"
      expected = "\n<pre class=\"code highlight js-syntax-highlight ruby\">" \
        "<code><span class=\"line\"><span class=\"k\">def</span> <span class=\"nf\">test</span>...</span>\n" \
        "</code></pre>"
      expect(helper.event_note(input)).to eq(expected)
    end

    it 'preserves data-src for lazy images' do
      input = "![ImageTest](/uploads/test.png)"
      image_url = "data-src=\"/uploads/test.png\""
      expect(helper.event_note(input)).to match(image_url)
    end

    context 'labels formatting' do
      let(:input) { 'this should be ~label_1' }

      def format_event_note(project)
        create(:label, title: 'label_1', project: project)

        helper.event_note(input, { project: project })
      end

      it 'preserves style attribute for a label that can be accessed by current_user' do
        project = create(:project, :public)

        expect(format_event_note(project)).to match(/span class=.*style=.*/)
      end

      it 'does not style a label that can not be accessed by current_user' do
        project = create(:project, :private)

        expect(format_event_note(project)).to eq("<p>#{input}</p>")
      end
    end
  end

  describe '#event_commit_title' do
    let(:message) { "foo & bar " + "A" * 70 + "\n" + "B" * 80 }
    subject { helper.event_commit_title(message) }

    it "returns the first line, truncated to 70 chars" do
      is_expected.to eq(message[0..66] + "...")
    end

    it "is not html-safe" do
      is_expected.not_to be_a(ActiveSupport::SafeBuffer)
    end

    it "handles empty strings" do
      expect(helper.event_commit_title("")).to eq("")
    end

    it 'handles nil values' do
      expect(helper.event_commit_title(nil)).to eq('')
    end
  end
end
