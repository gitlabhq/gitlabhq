# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::DiffFileHeaderComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }
  let(:header) { page.find('[data-testid="rd-diff-file-header"]') }

  it "renders file path" do
    project = diff_file.repository.project
    namespace = project.namespace
    href = "/#{namespace.to_param}/#{project.to_param}/-/blob/#{diff_file.content_sha}/#{diff_file.new_path}"
    render_component
    link = header.find('h2 a')
    expect(link.text).to eq(diff_file.file_path)
    expect(link[:href]).to eq(href)
  end

  it "renders file toggle" do
    render_component
    expect(header).to have_css('button[data-click="toggleFile"][aria-expanded="true"][aria-label="Hide file contents"]')
    expect(header)
      .to have_css('button[data-click="toggleFile"][aria-expanded="false"][aria-label="Show file contents"]')
  end

  it "renders copy path button" do
    clipboard_text = '{"text":"files/ruby/popen.rb","gfm":"`files/ruby/popen.rb`"}'
    button_selector = '[data-testid="rd-diff-file-header"] [data-testid="rd-diff-file-copy-clipboard"]'
    icon_selector = "#{button_selector} svg use"

    render_component

    expect(page.find(button_selector)['data-clipboard-text']).to eq(clipboard_text)
    expect(page.find(button_selector)['title']).to eq(_('Copy file path'))
    expect(page.find(icon_selector)['href']).to include('copy-to-clipboard')
  end

  it "renders path change" do
    old = 'old/path'
    new = 'new/path'
    allow(diff_file).to receive(:renamed_file?).and_return(true)
    allow(diff_file).to receive(:old_path).and_return(old)
    allow(diff_file).to receive(:new_path).and_return(new)
    render_component
    expect(header).to have_css("h2[aria-label=\"File moved from #{old} to #{new}\"] a", text: "#{old}→#{new}")
  end

  it "renders mode change" do
    allow(diff_file).to receive(:mode_changed?).and_return(true)
    render_component
    expect(header).to have_css('small', text: "#{diff_file.a_mode} → #{diff_file.b_mode}")
  end

  it "renders deleted message" do
    allow(diff_file).to receive(:deleted_file?).and_return(true)
    render_component
    expect(header).to have_text('deleted')
  end

  it "renders LFS message" do
    allow(diff_file).to receive(:stored_externally?).and_return(true)
    allow(diff_file).to receive(:external_storage).and_return(:lfs)
    render_component
    expect(header).to have_text('LFS')
  end

  it "renders line count" do
    render_component
    selector = "[aria-label=\"Added #{diff_file.added_lines} lines. Removed #{diff_file.removed_lines} lines.\"]"
    expect(page.find(selector)).to have_text("+#{diff_file.added_lines} −#{diff_file.removed_lines}")
  end

  context 'with a submodule diff' do
    let(:instance) { create_instance }
    let(:submodule_link) { nil }
    let(:submodule_diff_compare_data) { nil }

    before do
      allow(diff_file).to receive(:submodule?).and_return(true)
      allow(instance).to receive(:helpers).and_wrap_original do |original_method, *args|
        helpers = original_method.call(*args)
        allow(helpers).to receive_messages(submodule_link: submodule_link)
        allow(helpers).to receive_messages(submodule_diff_compare_data: { title: 'Compare a to b', href: '/compare' })
        helpers
      end
    end

    context "with submodule link" do
      let(:submodule_link) { 'submodule-link' }

      it "renders submodule info" do
        render_inline(instance)
        expect(page.find('[data-testid="rd-diff-file-header-submodule"] svg use')['href']).to include('folder-git')
        expect(page.find('[data-testid="rd-diff-file-header-submodule"] h2')).to have_text('submodule-link')
      end
    end

    context "with submodule diff compare data" do
      let(:submodule_diff_compare_data) { { title: 'Compare a to b', href: '/compare' } }

      it "renders submodule compare link" do
        render_inline(instance)
        link = page.find('[data-testid="rd-diff-file-submodule-compare"]')
        expect(link).not_to be_nil
        expect(link[:href]).to eq('/compare')
        expect(link.text).to include('Compare a to b')
      end
    end
  end

  context "with blob diff" do
    before do
      allow(diff_file).to receive(:binary?).and_return(true)
      allow(diff_file).to receive(:stored_externally?).and_return(false)
      allow(diff_file).to receive_message_chain(:old_blob, :size).and_return(100)
      allow(diff_file).to receive_message_chain(:new_blob, :size).and_return(1024)
    end

    it "renders added blob size" do
      allow(diff_file).to receive(:new_file?).and_return(true)
      render_component
      expect(page).to have_text("+1 KiB")
    end

    it "renders deleted blob size" do
      allow(diff_file).to receive(:new_file?).and_return(false)
      allow(diff_file).to receive(:deleted_file?).and_return(true)
      render_component
      expect(page).to have_text("−100 B")
    end

    context 'with changed blob' do
      before do
        allow(diff_file).to receive(:new_file?).and_return(false)
        allow(diff_file).to receive(:deleted_file?).and_return(false)
      end

      it "renders blob size changed to more bytes" do
        render_component
        expect(page).to have_text("+924 B (1 KiB)")
      end

      it "renders blob size changed to less bytes changed" do
        allow(diff_file).to receive_message_chain(:old_blob, :size).and_return(2048)
        render_component
        expect(page).to have_text("−1 KiB (1 KiB)")
      end
    end
  end

  describe 'menu items' do
    let(:content_sha) { 'abc123' }

    before do
      allow(diff_file).to receive(:content_sha).and_return(content_sha)
    end

    it 'always renders the "View file at [SHA]" menu item' do
      render_component

      options_menu_items = Gitlab::Json.parse(page.find('script', visible: false).text)

      expect(options_menu_items.first['text']).to eq('View file at abc123')
    end

    it 'renders additional menu items with respective order' do
      menu_items = [
        {
          text: 'First item',
          href: '/first',
          position: -100
        },
        {
          text: 'Last item',
          href: '/last',
          position: 100
        }
      ]

      render_component(additional_menu_items: menu_items)

      options_menu_items = Gitlab::Json.parse(page.find('script', visible: false).text)

      expect(page).to have_css('button[data-click="toggleOptionsMenu"][aria-label="Show options"]')
      expect(options_menu_items.first['text']).to eq('First item')
      expect(options_menu_items.last['text']).to eq('Last item')

      options_menu_items.each do |item|
        expect(item).not_to have_key('position')
      end
    end
  end

  def create_instance(**args)
    described_class.new(diff_file:, **args)
  end

  def render_component(**args)
    render_inline(create_instance(**args))
  end
end
