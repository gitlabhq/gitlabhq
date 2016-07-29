require 'spec_helper'

describe HelpController do
  let(:user) { create(:user) }

  before do
    sign_in(user)
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
end
