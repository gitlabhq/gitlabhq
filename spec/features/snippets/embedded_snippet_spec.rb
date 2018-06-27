require 'spec_helper'

describe 'Embedded Snippets' do
  let(:snippet) { create(:personal_snippet, :public, file_name: 'random_dir.rb', content: content) }
  let(:content) { "require 'fileutils'\nFileUtils.mkdir_p 'some/random_dir'\n" }

  it 'loads snippet', :js do
    script_url = "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}/#{snippet_path(snippet, format: 'js')}"
    embed_body = "<html><body><script src=\"#{script_url}\"></script></body></html>"

    rack_app = proc do
      ['200', { 'Content-Type' => 'text/html' }, [embed_body]]
    end

    server = Capybara::Server.new(rack_app)
    server.boot

    visit("http://#{server.host}:#{server.port}/embedded_snippet.html")

    expect(page).to have_content("random_dir.rb")
    expect(page).to have_content("require 'fileutils'")
    expect(page).to have_link('Open raw')
    expect(page).to have_link('Download')
  end
end
