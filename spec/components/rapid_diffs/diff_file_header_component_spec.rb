# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::DiffFileHeaderComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }
  let(:header) { page.find('[data-testid="rd-diff-file-header"]') }

  it "renders file path" do
    render_component
    expect(header).to have_text(diff_file.file_path)
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
    expect(page).to have_text(diff_file.blob.name)
    expect(page).to have_text(diff_file.blob.id[0..7])
  end

  it "renders path change" do
    allow(diff_file).to receive(:renamed_file?).and_return(true)
    allow(diff_file).to receive(:old_path).and_return('old/path')
    allow(diff_file).to receive(:new_path).and_return('new/path')
    render_component
    expect(header).to have_text('old/path')
    expect(header).to have_text('new/path')
  end

  it "renders mode change" do
    allow(diff_file).to receive(:mode_changed?).and_return(true)
    render_component
    expect(header).to have_text("#{diff_file.a_mode} → #{diff_file.b_mode}")
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
    expect(page.find('[data-testid="js-file-addition-line"]')).to have_text(diff_file.added_lines)
    expect(page.find('[data-testid="js-file-deletion-line"]')).to have_text(diff_file.removed_lines)
  end

  def render_component
    render_inline(described_class.new(diff_file: diff_file))
  end
end
