require 'spec_helper'

describe HelpController do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    context 'when url prefixed without /help/' do
      it 'has correct url prefix' do
        stub_readme("[API](api/README.md)")
        get :index
        expect(assigns[:help_index]).to eq '[API](/help/api/README.md)'
      end
    end

    context 'when url prefixed with help' do
      it 'will be an absolute path' do
        stub_readme("[API](helpful_hints/README.md)")
        get :index
        expect(assigns[:help_index]).to eq '[API](/help/helpful_hints/README.md)'
      end
    end

    context 'when url is an external link' do
      it 'will not be changed' do
        stub_readme("[external](https://some.external.link)")
        get :index
        expect(assigns[:help_index]).to eq '[external](https://some.external.link)'
      end
    end
  end

  describe 'GET #show' do
    context 'for Markdown formats' do
      context 'when requested file exists' do
        before do
          get :show, path: 'ssh/README', format: :md
        end

        it 'assigns to @markdown' do
          expect(assigns[:markdown]).not_to be_empty
        end

        it 'renders HTML' do
          expect(response).to render_template('show.html.haml')
          expect(response.content_type).to eq 'text/html'
        end
      end

      context 'when requested file is missing' do
        it 'renders not found' do
          get :show, path: 'foo/bar', format: :md
          expect(response).to be_not_found
        end
      end
    end

    context 'for image formats' do
      context 'when requested file exists' do
        it 'renders the raw file' do
          get :show,
              path: 'user/project/img/labels_filter',
              format: :png
          expect(response).to be_success
          expect(response.content_type).to eq 'image/png'
          expect(response.headers['Content-Disposition']).to match(/^inline;/)
        end
      end

      context 'when requested file is missing' do
        it 'renders not found' do
          get :show,
              path: 'foo/bar',
              format: :png
          expect(response).to be_not_found
        end
      end
    end

    context 'for other formats' do
      it 'always renders not found' do
        get :show,
            path: 'ssh/README',
            format: :foo
        expect(response).to be_not_found
      end
    end
  end

  describe 'GET #ui' do
    context 'for UI Development Kit' do
      it 'renders found' do
        get :ui
        expect(response).to have_http_status(200)
      end
    end
  end

  def stub_readme(content)
    allow(File).to receive(:read).and_return(content)
  end
end
