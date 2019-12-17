# frozen_string_literal: true

require 'spec_helper'

describe MarkupHelper do
  set(:project) { create(:project, :repository) }
  set(:user) do
    user = create(:user, username: 'gfm')
    project.add_maintainer(user)
    user
  end
  set(:issue) { create(:issue, project: project) }
  set(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  set(:snippet) { create(:project_snippet, project: project) }
  let(:commit) { project.commit }

  before do
    # Helper expects a @project instance variable
    helper.instance_variable_set(:@project, project)

    # Stub the `current_user` helper
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe "#markdown" do
    describe "referencing multiple objects" do
      let(:actual) { "#{merge_request.to_reference} -> #{commit.to_reference} -> #{issue.to_reference}" }

      it "links to the merge request" do
        expected = urls.project_merge_request_path(project, merge_request)
        expect(helper.markdown(actual)).to match(expected)
      end

      it "links to the commit" do
        expected = urls.project_commit_path(project, commit)
        expect(helper.markdown(actual)).to match(expected)
      end

      it "links to the issue" do
        expected = urls.project_issue_path(project, issue)
        expect(helper.markdown(actual)).to match(expected)
      end
    end

    describe "override default project" do
      let(:actual) { issue.to_reference }

      set(:second_project) { create(:project, :public) }
      set(:second_issue) { create(:issue, project: second_project) }

      it 'links to the issue' do
        expected = urls.project_issue_path(second_project, second_issue)
        expect(markdown(actual, project: second_project)).to match(expected)
      end
    end

    describe 'uploads' do
      let(:text) { "![ImageTest](/uploads/test.png)" }

      set(:group) { create(:group) }

      subject { helper.markdown(text) }

      describe 'inside a project' do
        it 'renders uploads relative to project' do
          expect(subject).to include("#{project.full_path}/uploads/test.png")
        end
      end

      describe 'inside a group' do
        before do
          helper.instance_variable_set(:@group, group)
          helper.instance_variable_set(:@project, nil)
        end

        it 'renders uploads relative to the group' do
          expect(subject).to include("#{group.full_path}/-/uploads/test.png")
        end
      end

      describe "with a group in the context" do
        set(:project_in_group) { create(:project, group: group) }

        before do
          helper.instance_variable_set(:@group, group)
          helper.instance_variable_set(:@project, project_in_group)
        end

        it 'renders uploads relative to project' do
          expect(subject).to include("#{project_in_group.path_with_namespace}/uploads/test.png")
        end
      end
    end

    context 'when text contains a relative link to an image in the repository' do
      let(:image_file) { "logo-white.png" }
      let(:text_with_relative_path) { "![](./#{image_file})\n" }
      let(:generated_html) { helper.markdown(text_with_relative_path, requested_path: requested_path) }

      subject { Nokogiri::HTML.parse(generated_html) }

      context 'when requested_path is provided in the context' do
        let(:requested_path) { 'files/images/README.md' }

        it 'returns the correct HTML for the image' do
          expanded_path = "/#{project.full_path}/-/raw/master/files/images/#{image_file}"

          expect(subject.css('a')[0].attr('href')).to eq(expanded_path)
          expect(subject.css('img')[0].attr('data-src')).to eq(expanded_path)
        end
      end

      context 'when requested_path parameter is not provided' do
        let(:requested_path) { nil }

        it 'returns the link to the image path as a relative path' do
          expanded_path = "/#{project.full_path}/master/./#{image_file}"

          expect(subject.css('a')[0].attr('href')).to eq(expanded_path)
        end
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

    # Clean the cache to make sure the title is re-rendered from the stubbed one
    it 'handles references nested in links with all the text', :clean_gitlab_redis_cache do
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
        .to eq urls.project_issue_path(project, issues[0])
      expect(doc.css('a')[1].text).to eq issues[0].to_reference

      # Internal commit link
      expect(doc.css('a')[2].attr('href')).to eq link
      expect(doc.css('a')[2].text).to eq ' and '

      # Second issue link
      expect(doc.css('a')[3].attr('href'))
        .to eq urls.project_issue_path(project, issues[1])
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
        .to eq urls.project_issue_path(project, issues[0])
      expect(doc.css('a')[1].text).to eq issues[0].to_reference

      # Internal commit link
      expect(doc.css('a')[2].attr('href')).to eq link
      expect(doc.css('a')[2].text).to eq ' and '

      # Second issue link
      expect(doc.css('a')[3].attr('href'))
        .to eq urls.project_issue_path(project, issues[1])
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
        .to eq '<a href="/foo"><gl-emoji title="open book" data-name="book" data-unicode-version="6.0">📖</gl-emoji></a><a href="/foo"> Book</a>'
    end
  end

  describe '#link_to_html' do
    it 'wraps the rendered content in a link' do
      link = '/commits/0a1b2c3d'
      issue = create(:issue, project: project)

      rendered = helper.markdown("This should finally fix #{issue.to_reference} for real", pipeline: :single_line)
      doc = Nokogiri::HTML.parse(rendered)

      expect(doc.css('a')[0].attr('href'))
        .to eq urls.project_issue_path(project, issue)
      expect(doc.css('a')[0].text).to eq issue.to_reference

      wrapped = helper.link_to_html(rendered, link)
      doc = Nokogiri::HTML.parse(wrapped)

      expect(doc.css('a')[0].attr('href')).to eq link
      expect(doc.css('a')[0].text).to eq 'This should finally fix '
    end

    it "escapes HTML passed as an emoji" do
      rendered = '<gl-emoji>&lt;div class="test"&gt;test&lt;/div&gt;</gl-emoji>'
      expect(helper.link_to_html(rendered, '/foo'))
        .to eq '<a href="/foo"><gl-emoji>&lt;div class="test"&gt;test&lt;/div&gt;</gl-emoji></a>'
    end
  end

  describe '#render_wiki_content' do
    let(:wiki) { double('WikiPage', path: "file.#{extension}") }
    let(:context) do
      {
        pipeline: :wiki, project: project, project_wiki: wiki,
        page_slug: 'nested/page', issuable_state_filter_enabled: true
      }
    end

    before do
      expect(wiki).to receive(:content).and_return('wiki content')
      expect(wiki).to receive(:slug).and_return('nested/page')
      helper.instance_variable_set(:@project_wiki, wiki)
    end

    context 'when file is Markdown' do
      let(:extension) { 'md' }

      it 'renders using #markdown_unsafe helper method' do
        expect(helper).to receive(:markdown_unsafe).with('wiki content', context)

        helper.render_wiki_content(wiki)
      end
    end

    context 'when file is Asciidoc' do
      let(:extension) { 'adoc' }

      it 'renders using Gitlab::Asciidoc' do
        expect(Gitlab::Asciidoc).to receive(:render)

        helper.render_wiki_content(wiki)
      end
    end

    context 'any other format' do
      let(:extension) { 'foo' }

      it 'renders all other formats using Gitlab::OtherMarkup' do
        expect(Gitlab::OtherMarkup).to receive(:render)

        helper.render_wiki_content(wiki)
      end
    end
  end

  describe '#markup' do
    let(:content) { 'Noël' }

    it 'preserves encoding' do
      expect(content.encoding.name).to eq('UTF-8')
      expect(helper.markup('foo.rst', content).encoding.name).to eq('UTF-8')
    end

    it 'delegates to #markdown_unsafe when file name corresponds to Markdown' do
      expect(helper).to receive(:gitlab_markdown?).with('foo.md').and_return(true)
      expect(helper).to receive(:markdown_unsafe).and_return('NOEL')

      expect(helper.markup('foo.md', content)).to eq('NOEL')
    end

    it 'delegates to #asciidoc_unsafe when file name corresponds to AsciiDoc' do
      expect(helper).to receive(:asciidoc?).with('foo.adoc').and_return(true)
      expect(helper).to receive(:asciidoc_unsafe).and_return('NOEL')

      expect(helper.markup('foo.adoc', content)).to eq('NOEL')
    end

    it 'uses passed in rendered content' do
      expect(helper).not_to receive(:gitlab_markdown?)
      expect(helper).not_to receive(:markdown_unsafe)

      expect(helper.markup('foo.md', content, rendered: '<p>NOEL</p>')).to eq('<p>NOEL</p>')
    end

    it 'defaults to CommonMark' do
      expect(helper.markup('foo.md', 'x^2')).to include('x^2')
    end
  end

  describe '#markup_unsafe' do
    subject { helper.markup_unsafe(file_name, text, context) }

    let(:file_name) { 'foo.bar' }
    let(:text) { 'Noël' }
    let(:project_base) { build(:project, :repository) }
    let(:context) { { project: project_base } }

    context 'when text is missing' do
      let(:text) { nil }

      it 'returns an empty string' do
        is_expected.to eq('')
      end
    end

    context 'when file is a markdown file' do
      let(:file_name) { 'foo.md' }

      it 'returns html (rendered by Banzai)' do
        expected_html = '<p data-sourcepos="1:1-1:5" dir="auto">Noël</p>'

        expect(Banzai).to receive(:render).with(text, context) { expected_html }

        is_expected.to eq(expected_html)
      end

      context 'when renderer returns an error' do
        before do
          allow(Banzai).to receive(:render).and_raise("An error")
        end

        it 'returns html (rendered by ActionView:TextHelper)' do
          is_expected.to eq('<p>Noël</p>')
        end
      end
    end

    context 'when file is asciidoc file' do
      let(:file_name) { 'foo.adoc' }

      it 'returns html (rendered by Gitlab::Asciidoc)' do
        expected_html = "<div>\n<p>Noël</p>\n</div>"

        expect(Gitlab::Asciidoc).to receive(:render).with(text, context) { expected_html }

        is_expected.to eq(expected_html)
      end
    end

    context 'when file is a regular text file' do
      let(:file_name) { 'foo.txt' }

      it 'returns html (rendered by ActionView::TagHelper)' do
        is_expected.to eq('<pre class="plain-readme">Noël</pre>')
      end
    end

    context 'when file has an unknown type' do
      let(:file_name) { 'foo' }

      it 'returns html (rendered by Gitlab::OtherMarkup)' do
        expected_html = 'Noël'

        expect(Gitlab::OtherMarkup).to receive(:render).with(file_name, text, context) { expected_html }

        is_expected.to eq(expected_html)
      end
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
        link_url = 'http://example.com/foo/bar/baz' # 30 chars
        input = "#{text}#{text}#{text} #{link_url}" # 163 chars
        expected_link_text = 'http://example...</a>'

        object = create_object(input)

        expect(first_line_in_markdown(object, attribute, 150, project: project)).to match(link_url)
        expect(first_line_in_markdown(object, attribute, 150, project: project)).to match(expected_link_text)
      end

      it 'preserves code color scheme' do
        object = create_object("```ruby\ndef test\n  'hello world'\nend\n```")
        expected = "<pre class=\"code highlight js-syntax-highlight ruby\">" \
          "<code><span class=\"line\"><span class=\"k\">def</span> <span class=\"nf\">test</span>...</span>\n" \
          "</code></pre>"

        expect(first_line_in_markdown(object, attribute, 150, project: project)).to eq(expected)
      end

      context 'when images are allowed' do
        it 'preserves data-src for lazy images' do
          object    = create_object("![ImageTest](/uploads/test.png)")
          image_url = "data-src=\".*/uploads/test.png\""
          text      = first_line_in_markdown(object, attribute, 150, project: project, allow_images: true)

          expect(text).to match(image_url)
          expect(text).to match('<a')
        end
      end

      context 'when images are not allowed' do
        it 'removes any images' do
          object = create_object("![ImageTest](/uploads/test.png)")
          text   = first_line_in_markdown(object, attribute, 150, project: project)

          expect(text).not_to match('<img')
          expect(text).not_to match('<a')
        end
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

  def urls
    Gitlab::Routing.url_helpers
  end
end
