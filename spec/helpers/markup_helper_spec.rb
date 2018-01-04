require 'spec_helper'

describe MarkupHelper do
  let!(:project) { create(:project, :repository) }

  let(:user)          { create(:user, username: 'gfm') }
  let(:commit)        { project.commit }
  let(:issue)         { create(:issue, project: project) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:snippet)       { create(:project_snippet, project: project) }

  before do
    # Ensure the generated reference links aren't redacted
    project.add_master(user)

    # Helper expects a @project instance variable
    helper.instance_variable_set(:@project, project)

    # Stub the `current_user` helper
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe "#markdown" do
    describe "referencing multiple objects" do
      let(:actual) { "#{merge_request.to_reference} -> #{commit.to_reference} -> #{issue.to_reference}" }

      it "links to the merge request" do
        expected = project_merge_request_path(project, merge_request)
        expect(helper.markdown(actual)).to match(expected)
      end

      it "links to the commit" do
        expected = project_commit_path(project, commit)
        expect(helper.markdown(actual)).to match(expected)
      end

      it "links to the issue" do
        expected = project_issue_path(project, issue)
        expect(helper.markdown(actual)).to match(expected)
      end
    end

    describe "override default project" do
      let(:actual) { issue.to_reference }
      let(:second_project) { create(:project, :public) }
      let(:second_issue) { create(:issue, project: second_project) }

      it 'links to the issue' do
        expected = project_issue_path(second_project, second_issue)
        expect(markdown(actual, project: second_project)).to match(expected)
      end
    end
  end

  describe '#markdown_field' do
    let(:attribute) { :title }

    describe 'with already redacted attribute' do
      it 'returns the redacted attribute' do
        commit.redacted_title_html = 'commit title'

        expect(Banzai).not_to receive(:render_field)

        expect(helper.markdown_field(commit, attribute)).to eq('commit title')
      end
    end

    describe 'without redacted attribute' do
      it 'renders the markdown value' do
        expect(Banzai).to receive(:render_field).with(commit, attribute, {}).and_call_original

        helper.markdown_field(commit, attribute)
      end
    end
  end

  describe '#link_to_markdown_field' do
    let(:link)    { '/commits/0a1b2c3d' }
    let(:issues)  { create_list(:issue, 2, project: project) }

    it 'handles references nested in links with all the text' do
      allow(commit).to receive(:title).and_return("This should finally fix #{issues[0].to_reference} and #{issues[1].to_reference} for real")

      actual = helper.link_to_markdown_field(commit, :title, link)
      doc = Nokogiri::HTML.parse(actual)

      # Make sure we didn't create invalid markup
      expect(doc.errors).to be_empty

      # Leading commit link
      expect(doc.css('a')[0].attr('href')).to eq link
      expect(doc.css('a')[0].text).to eq 'This should finally fix '

      # First issue link
      expect(doc.css('a')[1].attr('href'))
        .to eq project_issue_path(project, issues[0])
      expect(doc.css('a')[1].text).to eq issues[0].to_reference

      # Internal commit link
      expect(doc.css('a')[2].attr('href')).to eq link
      expect(doc.css('a')[2].text).to eq ' and '

      # Second issue link
      expect(doc.css('a')[3].attr('href'))
        .to eq project_issue_path(project, issues[1])
      expect(doc.css('a')[3].text).to eq issues[1].to_reference

      # Trailing commit link
      expect(doc.css('a')[4].attr('href')).to eq link
      expect(doc.css('a')[4].text).to eq ' for real'
    end
  end

  describe '#link_to_markdown' do
    let(:link)    { '/commits/0a1b2c3d' }
    let(:issues)  { create_list(:issue, 2, project: project) }

    it 'handles references nested in links with all the text' do
      actual = helper.link_to_markdown("This should finally fix #{issues[0].to_reference} and #{issues[1].to_reference} for real", link)
      doc = Nokogiri::HTML.parse(actual)

      # Make sure we didn't create invalid markup
      expect(doc.errors).to be_empty

      # Leading commit link
      expect(doc.css('a')[0].attr('href')).to eq link
      expect(doc.css('a')[0].text).to eq 'This should finally fix '

      # First issue link
      expect(doc.css('a')[1].attr('href'))
        .to eq project_issue_path(project, issues[0])
      expect(doc.css('a')[1].text).to eq issues[0].to_reference

      # Internal commit link
      expect(doc.css('a')[2].attr('href')).to eq link
      expect(doc.css('a')[2].text).to eq ' and '

      # Second issue link
      expect(doc.css('a')[3].attr('href'))
        .to eq project_issue_path(project, issues[1])
      expect(doc.css('a')[3].text).to eq issues[1].to_reference

      # Trailing commit link
      expect(doc.css('a')[4].attr('href')).to eq link
      expect(doc.css('a')[4].text).to eq ' for real'
    end

    it 'forwards HTML options' do
      actual = helper.link_to_markdown("Fixed in #{commit.id}", link, class: 'foo')
      doc = Nokogiri::HTML.parse(actual)

      expect(doc.css('a')).to satisfy do |v|
        # 'foo' gets added to all links
        v.all? { |a| a.attr('class').match(/foo$/) }
      end
    end

    it "escapes HTML passed in as the body" do
      actual = "This is a <h1>test</h1> - see #{issues[0].to_reference}"
      expect(helper.link_to_markdown(actual, link))
        .to match('&lt;h1&gt;test&lt;/h1&gt;')
    end

    it 'ignores reference links when they are the entire body' do
      text = issues[0].to_reference
      act = helper.link_to_markdown(text, '/foo')
      expect(act).to eq %Q(<a href="/foo">#{issues[0].to_reference}</a>)
    end

    it 'replaces commit message with emoji to link' do
      actual = link_to_markdown(':book: Book', '/foo')
      expect(actual)
        .to eq '<gl-emoji title="open book" data-name="book" data-unicode-version="6.0">📖</gl-emoji><a href="/foo"> Book</a>'
    end
  end

  describe '#link_to_html' do
    it 'wraps the rendered content in a link' do
      link = '/commits/0a1b2c3d'
      issue = create(:issue, project: project)

      rendered = helper.markdown("This should finally fix #{issue.to_reference} for real", pipeline: :single_line)
      doc = Nokogiri::HTML.parse(rendered)

      expect(doc.css('a')[0].attr('href'))
        .to eq project_issue_path(project, issue)
      expect(doc.css('a')[0].text).to eq issue.to_reference

      wrapped = helper.link_to_html(rendered, link)
      doc = Nokogiri::HTML.parse(wrapped)

      expect(doc.css('a')[0].attr('href')).to eq link
      expect(doc.css('a')[0].text).to eq 'This should finally fix '
    end
  end

  describe '#render_wiki_content' do
    before do
      @wiki = double('WikiPage')
      allow(@wiki).to receive(:content).and_return('wiki content')
      allow(@wiki).to receive(:slug).and_return('nested/page')
      helper.instance_variable_set(:@project_wiki, @wiki)
    end

    it "uses Wiki pipeline for markdown files" do
      allow(@wiki).to receive(:format).and_return(:markdown)

      expect(helper).to receive(:markdown_unsafe).with('wiki content', pipeline: :wiki, project: project, project_wiki: @wiki, page_slug: "nested/page", issuable_state_filter_enabled: true)

      helper.render_wiki_content(@wiki)
    end

    it "uses Asciidoctor for asciidoc files" do
      allow(@wiki).to receive(:format).and_return(:asciidoc)

      expect(helper).to receive(:asciidoc_unsafe).with('wiki content')

      helper.render_wiki_content(@wiki)
    end

    it "uses the Gollum renderer for all other file types" do
      allow(@wiki).to receive(:format).and_return(:rdoc)
      formatted_content_stub = double('formatted_content')
      expect(formatted_content_stub).to receive(:html_safe)
      allow(@wiki).to receive(:formatted_content).and_return(formatted_content_stub)

      helper.render_wiki_content(@wiki)
    end
  end

  describe 'markup' do
    let(:content) { 'Noël' }

    it 'preserves encoding' do
      expect(content.encoding.name).to eq('UTF-8')
      expect(helper.markup('foo.rst', content).encoding.name).to eq('UTF-8')
    end

    it "delegates to #markdown_unsafe when file name corresponds to Markdown" do
      expect(helper).to receive(:gitlab_markdown?).with('foo.md').and_return(true)
      expect(helper).to receive(:markdown_unsafe).and_return('NOEL')

      expect(helper.markup('foo.md', content)).to eq('NOEL')
    end

    it "delegates to #asciidoc_unsafe when file name corresponds to AsciiDoc" do
      expect(helper).to receive(:asciidoc?).with('foo.adoc').and_return(true)
      expect(helper).to receive(:asciidoc_unsafe).and_return('NOEL')

      expect(helper.markup('foo.adoc', content)).to eq('NOEL')
    end
  end

  describe '#first_line_in_markdown' do
    shared_examples_for 'common markdown examples' do
      let(:project_base) { build(:project, :repository) }

      it 'displays inline code' do
        object = create_object('Text with `inline code`')
        expected = 'Text with <code>inline code</code>'

        expect(first_line_in_markdown(object, attribute, 100, project: project)).to match(expected)
      end

      it 'truncates the text with multiple paragraphs' do
        object = create_object("Paragraph 1\n\nParagraph 2")
        expected = 'Paragraph 1...'

        expect(first_line_in_markdown(object, attribute, 100, project: project)).to match(expected)
      end

      it 'displays the first line of a code block' do
        object = create_object("```\nCode block\nwith two lines\n```")
        expected = %r{<pre.+><code><span class="line">Code block\.\.\.</span>\n</code></pre>}

        expect(first_line_in_markdown(object, attribute, 100, project: project)).to match(expected)
      end

      it 'truncates a single long line of text' do
        text = 'The quick brown fox jumped over the lazy dog twice' # 50 chars
        object = create_object(text * 4)
        expected = (text * 2).sub(/.{3}/, '...')

        expect(first_line_in_markdown(object, attribute, 150, project: project)).to match(expected)
      end

      it 'preserves a link href when link text is truncated' do
        text = 'The quick brown fox jumped over the lazy dog' # 44 chars
        input = "#{text}#{text}#{text} " # 133 chars
        link_url = 'http://example.com/foo/bar/baz' # 30 chars
        input << link_url
        object = create_object(input)
        expected_link_text = 'http://example...</a>'

        expect(first_line_in_markdown(object, attribute, 150, project: project)).to match(link_url)
        expect(first_line_in_markdown(object, attribute, 150, project: project)).to match(expected_link_text)
      end

      it 'preserves code color scheme' do
        object = create_object("```ruby\ndef test\n  'hello world'\nend\n```")
        expected = "\n<pre class=\"code highlight js-syntax-highlight ruby\">" \
          "<code><span class=\"line\"><span class=\"k\">def</span> <span class=\"nf\">test</span>...</span>\n" \
          "</code></pre>"

        expect(first_line_in_markdown(object, attribute, 150, project: project)).to eq(expected)
      end

      it 'preserves data-src for lazy images' do
        object = create_object("![ImageTest](/uploads/test.png)")
        image_url = "data-src=\".*/uploads/test.png\""

        expect(first_line_in_markdown(object, attribute, 150, project: project)).to match(image_url)
      end

      context 'labels formatting' do
        let(:label_title) { 'this should be ~label_1' }

        def create_and_format_label(project)
          create(:label, title: 'label_1', project: project)
          object = create_object(label_title, project: project)

          first_line_in_markdown(object, attribute, 150, project: project)
        end

        it 'preserves style attribute for a label that can be accessed by current_user' do
          project = create(:project, :public)

          expect(create_and_format_label(project)).to match(/span class=.*style=.*/)
        end

        it 'does not style a label that can not be accessed by current_user' do
          project = create(:project, :private)

          expect(create_and_format_label(project)).to eq("<p>#{label_title}</p>")
        end
      end

      it 'truncates Markdown properly' do
        object = create_object("@#{user.username}, can you look at this?\nHello world\n")
        actual = first_line_in_markdown(object, attribute, 100, project: project)

        doc = Nokogiri::HTML.parse(actual)

        # Make sure we didn't create invalid markup
        expect(doc.errors).to be_empty

        # Leading user link
        expect(doc.css('a').length).to eq(1)
        expect(doc.css('a')[0].attr('href')).to eq user_path(user)
        expect(doc.css('a')[0].text).to eq "@#{user.username}"

        expect(doc.content).to eq "@#{user.username}, can you look at this?..."
      end

      it 'truncates Markdown with emoji properly' do
        object = create_object("foo :wink:\nbar :grinning:")
        actual = first_line_in_markdown(object, attribute, 100, project: project)

        doc = Nokogiri::HTML.parse(actual)

        # Make sure we didn't create invalid markup
        # But also account for the 2 errors caused by the unknown `gl-emoji` elements
        expect(doc.errors.length).to eq(2)

        expect(doc.css('gl-emoji').length).to eq(2)
        expect(doc.css('gl-emoji')[0].attr('data-name')).to eq 'wink'
        expect(doc.css('gl-emoji')[1].attr('data-name')).to eq 'grinning'

        expect(doc.content).to eq "foo 😉\nbar 😀"
      end
    end

    context 'when the asked attribute can be redacted' do
      include_examples 'common markdown examples' do
        let(:attribute) { :note }
        def create_object(title, project: project_base)
          build(:note, note: title, project: project)
        end
      end
    end

    context 'when the asked attribute can not be redacted' do
      include_examples 'common markdown examples' do
        let(:attribute) { :body }
        def create_object(title, project: project_base)
          issue = build(:issue, title: title)
          build(:todo, :done, project: project_base, author: user, target: issue)
        end
      end
    end
  end

  describe '#cross_project_reference' do
    it 'shows the full MR reference' do
      expect(helper.cross_project_reference(project, merge_request)).to include(project.full_path)
    end

    it 'shows the full issue reference' do
      expect(helper.cross_project_reference(project, issue)).to include(project.full_path)
    end
  end
end
