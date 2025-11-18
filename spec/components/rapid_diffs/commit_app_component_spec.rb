# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::CommitAppComponent, feature_category: :code_review_workflow do
  let(:app_component) { instance_double(RapidDiffs::AppComponent) }
  let(:discussions_endpoint) { '/discussions' }
  let(:user_permissions) { { can_create_note: true } }
  let(:noteable_type) { 'Commit' }
  let(:preview_markdown_endpoint) { '/preview_markdown_endpoint' }
  let(:register_path) { '/register_path' }
  let(:sign_in_path) { '/sign_in_path' }
  let(:markdown_docs_path) { '/markdown_docs_path' }

  let(:presenter) do
    instance_double(
      ::RapidDiffs::CommitPresenter,
      discussions_endpoint: discussions_endpoint,
      user_permissions: user_permissions,
      noteable_type: noteable_type,
      preview_markdown_endpoint: preview_markdown_endpoint,
      register_path: register_path,
      sign_in_path: sign_in_path,
      markdown_docs_path: markdown_docs_path
    )
  end

  subject(:component) { described_class.new(presenter) }

  before do
    allow(RapidDiffs::AppComponent).to receive(:new).and_return(app_component)
    allow(app_component).to receive(:render_in).and_yield(app_component)
    allow(app_component).to receive(:with_before_diffs_list).and_yield
  end

  it "renders app with correct arguments" do
    expect(RapidDiffs::AppComponent).to receive(:new).with(
      presenter,
      extra_app_data: {
        discussions_endpoint: discussions_endpoint,
        user_permissions: user_permissions,
        noteable_type: noteable_type,
        preview_markdown_endpoint: preview_markdown_endpoint,
        register_path: register_path,
        sign_in_path: sign_in_path,
        markdown_docs_path: markdown_docs_path
      },
      extra_prefetch_endpoints: [discussions_endpoint]
    )

    render_component
  end

  context "when user has permission to create notes" do
    let(:user_permissions) { { can_create_note: true } }

    it "renders before_diffs_list slot with new discussion toggle" do
      render_component

      expect(page).to have_selector('[data-new-discussion-toggle][hidden]', visible: :all)
    end
  end

  context "when user does not have permission to create notes" do
    let(:user_permissions) { { can_create_note: false } }

    it "does not render before_diffs_list slot" do
      render_component

      expect(page).not_to have_selector('[data-new-discussion-toggle]', visible: :all)
    end
  end

  def render_component
    render_inline(component)
  end
end
