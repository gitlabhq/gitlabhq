# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MarkupHelper, feature_category: :markdown do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) do
    user = create(:user, username: 'gfm')
    project.add_maintainer(user)
    user
  end

  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:snippet) { create(:project_snippet, project: project) }

  let(:commit) { project.commit }

  before do
    # Helper expects a @project instance variable
    helper.instance_variable_set(:@project, project)

    # Stub the `current_user` helper
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe "#markdown" do
    context "referencing multiple objects" do
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

    context "override default project" do
      let(:actual) { issue.to_reference }

      let_it_be(:second_project) { create(:project, :public) }
      let_it_be(:second_issue) { create(:issue, project: second_project) }

      it 'links to the issue' do
        expected = urls.project_issue_path(second_project, second_issue)
        expect(markdown(actual, project: second_project)).to match(expected)
      end
    end

    context 'uploads' do
      let(:text) { "![ImageTest](/uploads/test.png)" }

      let_it_be(:group) { create(:group) }

      subject { helper.markdown(text) }

      describe 'inside a project' do
        it 'renders uploads relative to project' do
          expect(subject).to include("/-/project/#{project.id}/uploads/test.png")
        end
      end

      context 'inside a group' do
        before do
          helper.instance_variable_set(:@group, group)
          helper.instance_variable_set(:@project, nil)
        end

        it 'renders uploads relative to the group' do
          expect(subject).to include("/-/group/#{group.id}/uploads/test.png")
        end
      end

      context "with a group in the context" do
        let_it_be(:project_in_group) { create(:project, group: group) }

        before do
          helper.instance_variable_set(:@group, group)
          helper.instance_variable_set(:@project, project_in_group)
        end

        it 'renders uploads relative to project' do
          expect(subject).to include("/-/project/#{project_in_group.id}/uploads/test.png")
        end
      end
    end

    context 'when text contains a relative link to an image in the repository' do
      let(:image_file) { "logo-white.png" }
      let(:text_with_relative_path) { "![](./#{image_file})\n" }
      let(:generated_html) { helper.markdown(text_with_relative_path, requested_path: requested_path, ref: ref) }

      subject { Nokogiri::HTML.parse(generated_html) }

      context 'when requested_path is provided, but ref isn\'t' do
        let(:requested_path) { 'files/images/README.md' }
        let(:ref) { nil }

        it 'returns the correct HTML for the image' do
          expanded_path = "/#{project.full_path}/-/raw/master/files/images/#{image_file}"

          expect(subject.css('a')[0].attr('href')).to eq(expanded_path)
          expect(subject.css('img')[0].attr('data-src')).to eq(expanded_path)
        end
      end

      context 'when requested_path and ref parameters are both provided' do
        let(:requested_path) { 'files/images/README.md' }
        let(:ref) { 'other_branch' }

        it 'returns the correct HTML for the image' do
          project.repository.create_branch('other_branch')

          expanded_path = "/#{project.full_path}/-/raw/#{ref}/files/images/#{image_file}"

          expect(subject.css('a')[0].attr('href')).to eq(expanded_path)
          expect(subject.css('img')[0].attr('data-src')).to eq(expanded_path)
        end
      end

      context 'when ref is provided, but requested_path isn\'t' do
        let(:ref) { 'other_branch' }
        let(:requested_path) { nil }

        it 'returns the correct HTML for the image' do
          project.repository.create_branch('other_branch')

          expanded_path = "/#{project.full_path}/-/blob/#{ref}/./#{image_file}"

          expect(subject.css('a')[0].attr('href')).to eq(expanded_path)
          expect(subject.css('img')[0].attr('data-src')).to eq(expanded_path)
        end
      end

      context 'when neither requested_path, nor ref parameter is provided' do
        let(:ref) { nil }
        let(:requested_path) { nil }

        it 'returns the correct HTML for the image' do
          expanded_path = "/#{project.full_path}/-/blob/master/./#{image_file}"

          expect(subject.css('a')[0].attr('href')).to eq(expanded_path)
          expect(subject.css('img')[0].attr('data-src')).to eq(expanded_path)
        end
      end
    end

    context 'when there is a postprocessing option provided' do
      it 'passes the postprocess options to the Markup::RenderingService' do
        expect(Markup::RenderingService)
          .to receive(:new)
          .with('test', context: anything,
            postprocess_context: a_hash_including(requested_path: 'path')).and_call_original

        helper.markdown('test', {}, { requested_path: 'path' })
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
        expect(Banzai).to receive(:post_process)

        helper.markdown_field(commit, attribute)
      end
    end

    context 'when post_process is false' do
      it 'does not run Markdown post processing' do
        expect(Banzai).to receive(:render_field).with(commit, attribute, {}).and_call_original
        expect(Banzai).not_to receive(:post_process)

        helper.markdown_field(commit, attribute, post_process: false)
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
      expect(act).to eq %(<a href="/foo">#{issues[0].to_reference}</a>)
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
    let(:wiki) { build(:wiki, container: project) }
    let(:content) { 'wiki content' }
    let(:slug) { 'nested/page' }
    let(:path) { "file.#{extension}" }
    let(:wiki_page) { double('WikiPage', path: path, content: content, slug: slug, wiki: wiki) }

    let(:context) do
      {
        pipeline: :wiki, project: project, wiki: wiki,
        page_slug: slug, issuable_reference_expansion_enabled: true,
        repository: wiki.repository, requested_path: path
      }
    end

    context 'when file is Markdown' do
      let(:extension) { 'md' }

      it 'renders using CommonMark method' do
        expect(Banzai).to receive(:render).with('wiki content', context)

        helper.render_wiki_content(wiki_page)
      end

      context 'when context has labels' do
        let_it_be(:label) { create(:label, title: 'Bug', project: project) }

        let(:content) { '~Bug' }

        it 'renders label' do
          result = helper.render_wiki_content(wiki_page)
          doc = Nokogiri::HTML.parse(result)

          expect(doc.css('.gl-label-link')).not_to be_empty
        end
      end

      context 'when content has uploads' do
        let(:upload_link) { '/uploads/test.png' }
        let(:content) { "![ImageTest](#{upload_link})" }

        before do
          allow(wiki).to receive(:wiki_base_path).and_return(project.wiki.wiki_base_path)
        end

        it 'renders uploads relative to project' do
          result = helper.render_wiki_content(wiki_page)

          expect(result).to include("/-/project/#{project.id}#{upload_link}")
        end
      end
    end

    context 'when file is Asciidoc' do
      let(:extension) { 'adoc' }

      it 'renders using Gitlab::Asciidoc' do
        expect(Gitlab::Asciidoc).to receive(:render)

        helper.render_wiki_content(wiki_page)
      end
    end

    context 'when file is R Markdown' do
      let(:extension) { 'rmd' }
      let(:content) { '## Header' }

      it 'renders using CommonMark method' do
        expect(Markup::RenderingService).to receive(:new).and_call_original

        result = helper.render_wiki_content(wiki_page)

        expect(result).to include('Header</h2>')
      end
    end

    context 'any other format' do
      let(:extension) { 'foo' }

      it 'renders all other formats using Gitlab::OtherMarkup' do
        expect(Gitlab::OtherMarkup).to receive(:render)

        helper.render_wiki_content(wiki_page)
      end
    end
  end

  describe '#markup' do
    let(:content) { 'Noël' }

    it 'sets the :text_source to :blob in the context' do
      context = {}
      helper.markup('foo.md', content, context)

      expect(context).to include(text_source: :blob)
      expect(context).to include(requested_path: nil)
    end

    it 'sets the :requested_path to @path when :text_source is a blob' do
      context = {}
      assign(:path, 'path')

      helper.markup('foo.md', content, context)

      expect(context).to include(requested_path: 'path')
    end

    it 'preserves encoding' do
      expect(content.encoding.name).to eq('UTF-8')
      expect(helper.markup('foo.rst', content).encoding.name).to eq('UTF-8')
    end

    it 'uses passed in rendered content' do
      expect(Gitlab::MarkupHelper).not_to receive(:gitlab_markdown?)
      expect(Markup::RenderingService).not_to receive(:execute)

      expect(helper.markup('foo.md', content, rendered: '<p>NOEL</p>')).to eq('<p>NOEL</p>')
    end

    it 'defaults to CommonMark' do
      expect(helper.markup('foo.md', 'x^2')).to include('x^2')
    end

    it 'sets additional context for Asciidoc' do
      context = {}
      assign(:commit, commit)
      assign(:ref, 'ref')
      assign(:path, 'path')

      expect(Gitlab::Asciidoc).to receive(:render)

      helper.markup('foo.adoc', content, context)

      expect(context).to include(commit: commit, ref: 'ref', requested_path: 'path')
    end
  end

  describe '#first_line_in_markdown' do
    shared_examples_for 'common markdown examples' do
      let(:project_base) { build(:project, :repository) }

      it 'displays inline code' do
        object = create_object('Text with `inline code`')
        expected = 'Text with <code>inline code</code>'

        expect(helper.first_line_in_markdown(object, attribute, 100, project: project)).to match(expected)
      end

      it 'truncates the text with multiple paragraphs' do
        object = create_object("Paragraph 1\n\nParagraph 2")
        expected = 'Paragraph 1...'

        expect(helper.first_line_in_markdown(object, attribute, 100, project: project)).to match(expected)
      end

      it 'displays the first line of a code block' do
        object = create_object("```\nCode block\nwith two lines\n```")
        expected = %r{<pre.+><code><span class="line" lang="plaintext">Code block\.\.\.</span></code></pre>}

        expect(helper.first_line_in_markdown(object, attribute, 100, project: project)).to match(expected)
      end

      it 'truncates a single long line of text' do
        text = 'The quick brown fox jumped over the lazy dog twice' # 50 chars
        object = create_object(text * 4)
        expected = (text * 2).sub(/.{3}/, '...')

        expect(helper.first_line_in_markdown(object, attribute, 150, project: project)).to match(expected)
      end

      it 'preserves code color scheme' do
        object = create_object("```ruby\ndef test\n  'hello world'\nend\n```")
        expected = "\n<pre class=\"code highlight js-syntax-highlight language-ruby\">" \
          "<code><span class=\"line\" lang=\"ruby\"><span class=\"k\">def</span> <span class=\"nf\">test</span>...</span>" \
          "</code></pre>\n"

        expect(helper.first_line_in_markdown(object, attribute, 150, project: project)).to eq(expected)
      end

      it 'removes any images' do
        object = create_object("![ImageTest](/uploads/test.png)")
        text   = helper.first_line_in_markdown(object, attribute, 150, project: project)

        expect(text).not_to match('<img')
        expect(text).not_to match('<a')
      end

      context 'custom emoji' do
        it 'includes fallback-src data attribute' do
          group = create(:group)
          project = create(:project, :repository, group: group)
          custom_emoji = create(:custom_emoji, group: group)

          object = create_object(":#{custom_emoji.name}:", project: project)
          expected = "<p><gl-emoji title=\"#{custom_emoji.name}\" data-name=\"#{custom_emoji.name}\" data-fallback-src=\"#{custom_emoji.url}\" data-unicode-version=\"custom\"></gl-emoji></p>"

          expect(helper.first_line_in_markdown(object, attribute, 150, project: project)).to eq(expected)
        end
      end

      context 'labels formatting' do
        let(:label_title) { 'this should be ~label_1' }

        def create_and_format_label(project)
          create(:label, title: 'label_1', project: project)
          object = create_object(label_title, project: project)

          helper.first_line_in_markdown(object, attribute, 150, project: project)
        end

        it 'preserves style attribute for a label that can be accessed by current_user' do
          project = create(:project, :public)
          label = create_and_format_label(project)

          expect(label).to match(/span class=.*style=.*/)
          expect(label).to include('data-html="true"')
        end

        it 'does not style a label that can not be accessed by current_user' do
          project = create(:project, :private)
          label = create_and_format_label(project)

          expect(label).to include("~label_1")
          expect(label).not_to match(/span class=.*style=.*/)
        end
      end

      it 'keeps whitelisted tags' do
        html = '<i></i> <strong>strong</strong><em>em</em><b>b</b>'

        object = create_object(html)
        result = helper.first_line_in_markdown(object, attribute, 100, project: project)

        expect(result).to include(html)
      end

      it 'does not post-process truncated text', :request_store do
        object = create_object("hello \n\n [Test](README.md)")

        expect do
          helper.first_line_in_markdown(object, attribute, 100, project: project)
        end.not_to change { Gitlab::GitalyClient.get_request_count }
      end

      it 'strips non-user links' do
        html = 'This a cool [website](https://gitlab.com/).'

        object = create_object(html)
        result = helper.first_line_in_markdown(object, attribute, 100, project: project)

        expect(result).to include('This a cool website.')
      end

      it 'styles the current user link', :aggregate_failures do
        another_user = create(:user)
        html = "Please have a look, @#{user.username} @#{another_user.username}!"

        object = create_object(html)
        result = helper.first_line_in_markdown(object, attribute, 100, project: project)
        links = Nokogiri::HTML.parse(result).css('//a')

        expect(links[0].classes).to include('current-user')
        expect(links[1].classes).not_to include('current-user')
      end

      context 'when current_user is nil' do
        before do
          allow(helper).to receive(:current_user).and_return(nil)
        end

        it 'renders the link with no styling when current_user is nil' do
          another_user = create(:user)
          html = "Please have a look, @#{user.username} @#{another_user.username}!"

          object = create_object(html)
          result = helper.first_line_in_markdown(object, attribute, 100, project: project)
          links = Nokogiri::HTML.parse(result).css('//a')

          expect(links[0].classes).not_to include('current-user')
          expect(links[1].classes).not_to include('current-user')
        end
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
