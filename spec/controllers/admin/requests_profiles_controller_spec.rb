# frozen_string_literal: true

require 'spec_helper'

describe Admin::RequestsProfilesController do
  set(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe '#show' do
    let(:tmpdir) { Dir.mktmpdir('profiler-test') }
    let(:test_file) { File.join(tmpdir, basename) }

    subject do
      get :show, params: { name: basename }
    end

    before do
      stub_const('Gitlab::RequestProfiler::PROFILES_DIR', tmpdir)
      File.write(test_file, sample_data)
    end

    after do
      FileUtils.rm_rf(tmpdir)
    end

    context 'when loading HTML profile' do
      let(:basename) { "profile_#{Time.now.to_i}_execution.html" }

      let(:sample_data) do
        '<html> <body> <h1>Heading</h1> <p>paragraph.</p> </body> </html>'
      end

      it 'renders the data' do
        subject

        expect(response).to have_gitlab_http_status(200)
        expect(response.body).to eq(sample_data)
      end
    end

    context 'when loading TXT profile' do
      let(:basename) { "profile_#{Time.now.to_i}_memory.txt" }

      let(:sample_data) do
        <<~TXT
          Total allocated: 112096396 bytes (1080431 objects)
          Total retained:  10312598 bytes (53567 objects)
        TXT
      end

      it 'renders the data' do
        subject

        expect(response).to have_gitlab_http_status(200)
        expect(response.body).to eq(sample_data)
      end
    end

    context 'when loading PDF profile' do
      let(:basename) { "profile_#{Time.now.to_i}_anything.pdf" }

      let(:sample_data) { 'mocked pdf content' }

      it 'fails to render the data' do
        expect { subject }.to raise_error(ActionController::UrlGenerationError, /No route matches.*unmatched constraints:/)
      end
    end
  end
end
