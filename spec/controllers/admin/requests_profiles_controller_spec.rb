# frozen_string_literal: true

require 'spec_helper'

describe Admin::RequestsProfilesController do
  set(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe '#show' do
    let(:basename) { "profile_#{Time.now.to_i}.html" }
    let(:tmpdir) { Dir.mktmpdir('profiler-test') }
    let(:test_file) { File.join(tmpdir, basename) }
    let(:profile) { Gitlab::RequestProfiler::Profile.new(basename) }
    let(:sample_data) do
      <<~HTML
        <!DOCTYPE html>
        <html>
        <body>
        <h1>My First Heading</h1>
        <p>My first paragraph.</p>
        </body>
        </html>
      HTML
    end

    before do
      stub_const('Gitlab::RequestProfiler::PROFILES_DIR', tmpdir)
      output = File.open(test_file, 'w')
      output.write(sample_data)
      output.close
    end

    after do
      File.unlink(test_file)
    end

    it 'loads an HTML profile' do
      get :show, name: basename

      expect(response).to have_gitlab_http_status(200)
      expect(response.body).to eq(sample_data)
    end
  end
end
