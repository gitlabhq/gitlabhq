# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::DiffFileHeaderComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }
  let(:header) { page.find('[data-testid="rd-diff-file-header"]') }

  it "renders file path" do
    render_component
    expect(header).to have_css('h2', text: diff_file.file_path)
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

  it "renders submodule info", quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/489868' do
    allow(diff_file).to receive(:submodule?).and_return(true)
    allow_next_instance_of(SubmoduleHelper) do |instance|
      allow(instance).to receive(:submodule_links).and_return(nil)
    end
    render_component
    expect(page.find('[data-testid="rd-diff-file-header-submodule"] svg use')['href']).to include('folder-git')
    expect(page).to have_css('h2', text: diff_file.blob.name)
    expect(page).to have_css('h2', text: diff_file.blob.id[0..7])
  end

  it "renders path change" do
    old = 'old/path'
    new = 'new/path'
    allow(diff_file).to receive(:renamed_file?).and_return(true)
    allow(diff_file).to receive(:old_path).and_return(old)
    allow(diff_file).to receive(:new_path).and_return(new)
    render_component
    expect(header).to have_css("h2[aria-label=\"File moved from #{old} to #{new}\"]", text: "#{old}→#{new}")
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

  describe 'menu items' do
    let(:content_sha) { 'abc123' }

    before do
      allow(diff_file).to receive(:content_sha).and_return(content_sha)
    end

    it 'renders menu toggle' do
      render_component

      expect(page).to have_css('button[data-click="toggleOptionsMenu"][aria-label="Show options"]')
    end

    it 'renders default menu items' do
      render_component

      options_menu_items = Gitlab::Json.parse(page.find('script', visible: false).text)

      expect(options_menu_items.length).to eq(1)
      expect(options_menu_items[0]['text']).to eq("View file @ #{content_sha}")
      expect(options_menu_items[0]).not_to have_key('position')
    end

    it 'renders additional menu items with respective order' do
      menu_items = [
        {
          text: 'First item',
          href: '/first',
          position: -1
        },
        {
          text: 'Last item',
          href: '/last',
          position: 2
        }
      ]

      render_component(additional_menu_items: menu_items)

      options_menu_items = Gitlab::Json.parse(page.find('script', visible: false).text)

      expect(options_menu_items.length).to eq(3)
      expect(options_menu_items[0]['text']).to eq('First item')
      expect(options_menu_items[1]['text']).to eq("View file @ #{content_sha}")
      expect(options_menu_items[2]['text']).to eq('Last item')

      options_menu_items.each do |item|
        expect(item).not_to have_key('position')
      end
    end
  end

  def render_component(**args)
    render_inline(described_class.new(diff_file:, **args))
  end
end
