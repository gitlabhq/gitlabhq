require 'spec_helper'

describe 'Embedded Snippets' do
  include RSpec::Rails::RequestExampleGroup

  let(:project) { create(:project, :repository) }
  let(:snippet) { create(:personal_snippet, :public, file_name: 'popen.rb', content: content) }
  let(:content) { project.repository.blob_at('master', 'files/ruby/popen.rb').data }

  after do
    FileUtils.rm_f([File.join(File.dirname(__FILE__), 'embedded_snippet.html'), File.join(File.dirname(__FILE__), 'snippet.js')])
  end

  it 'loads snippet', :js do
    get "#{snippet_path(snippet)}.js"

    File.write(File.join(File.dirname(__FILE__), 'snippet.js'), response.body)

    script_tag = "<html><body><script src=\"snippet.js\"></script></body></html>"
    File.write(File.join(File.dirname(__FILE__), 'embedded_snippet.html'), script_tag)

    Capybara.app = Rack::File.new File.dirname __FILE__

    visit('embedded_snippet.html')

    expect(page).to have_content("popen.rb")

    expect(page).to have_content("require 'fileutils'")
  end
end
