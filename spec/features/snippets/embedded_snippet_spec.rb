# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Embedded Snippets', feature_category: :source_code_management do
  let_it_be(:snippet) { create(:personal_snippet, :public, :repository) }

  let(:blobs) { snippet.blobs.first(3) }

  it 'loads snippet', :js do
    expect_any_instance_of(Snippet).to receive(:blobs).and_return(blobs)

    script_url = "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}#{snippet_path(snippet, format: 'js')}"
    embed_body = "<html><body><script src=\"#{script_url}\"></script></body></html>"

    rack_app = proc do
      ['200', { 'Content-Type' => 'text/html' }, [embed_body]]
    end

    server = Capybara::Server.new(rack_app)
    server.boot

    visit("http://#{server.host}:#{server.port}/embedded_snippet.html")

    wait_for_requests

    aggregate_failures do
      blobs.each do |blob|
        expect(page).to have_content(blob.path)
        expect(page.find(".snippet-file-content .blob-content[data-blob-id='#{blob.id}'] code")).to have_content(blob.data.squish)
        expect(page).to have_link('Open raw', href: %r{-/snippets/#{snippet.id}/raw/master/#{blob.path}})
        expect(page).to have_link('Download', href: %r{-/snippets/#{snippet.id}/raw/master/#{blob.path}\?inline=false})
      end
    end
  end
end
