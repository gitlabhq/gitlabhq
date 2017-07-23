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
    project.team << [user, :master]

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

  describe '#link_to_gfm' do
    let(:link)    { '/commits/0a1b2c3d' }
    let(:issues)  { create_list(:issue, 2, project: project) }

    it 'handles references nested in links with all the text' do
      actual = helper.link_to_gfm("This should finally fix #{issues[0].to_reference} and #{issues[1].to_reference} for real", link)
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
      actual = helper.link_to_gfm("Fixed in #{commit.id}", link, class: 'foo')
      doc = Nokogiri::HTML.parse(actual)

      expect(doc.css('a')).to satisfy do |v|
        # 'foo' gets added to all links
        v.all? { |a| a.attr('class').match(/foo$/) }
      end
    end

    it "escapes HTML passed in as the body" do
      actual = "This is a <h1>test</h1> - see #{issues[0].to_reference}"
      expect(helper.link_to_gfm(actual, link))
        .to match('&lt;h1&gt;test&lt;/h1&gt;')
    end

    it 'ignores reference links when they are the entire body' do
      text = issues[0].to_reference
      act = helper.link_to_gfm(text, '/foo')
      expect(act).to eq %Q(<a href="/foo">#{issues[0].to_reference}</a>)
    end

    it 'replaces commit message with emoji to link' do
      actual = link_to_gfm(':book: Book', '/foo')
      expect(actual)
        .to eq '<gl-emoji title="open book" data-name="book" data-unicode-version="6.0">📖</gl-emoji><a href="/foo"> Book</a>'
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

      expect(helper).to receive(:markdown_unsafe).with('wiki content', pipeline: :wiki, project: project, project_wiki: @wiki, page_slug: "nested/page")

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
    it 'truncates Markdown properly' do
      text = "@#{user.username}, can you look at this?\nHello world\n"
      actual = first_line_in_markdown(text, 100, project: project)

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
      text = "foo :wink:\nbar :grinning:"
      actual = first_line_in_markdown(text, 100, project: project)

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

  describe '#cross_project_reference' do
    it 'shows the full MR reference' do
      expect(helper.cross_project_reference(project, merge_request)).to include(project.path_with_namespace)
    end

    it 'shows the full issue reference' do
      expect(helper.cross_project_reference(project, issue)).to include(project.path_with_namespace)
    end
  end
end
