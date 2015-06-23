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
          get :show, category: 'ssh', file: 'README', format: :md
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
          get :show, category: 'foo', file: 'bar', format: :md
          expect(response).to be_not_found
        end
      end
    end

    context 'for image formats' do
      context 'when requested file exists' do
        it 'renders the raw file' do
          get :show,
              category: 'workflow/protected_branches',
              file: 'protected_branches1',
              format: :png
          expect(response).to be_success
          expect(response.content_type).to eq 'image/png'
          expect(response.headers['Content-Disposition']).to match(/^inline;/)
        end
      end

      context 'when requested file is missing' do
        it 'renders not found' do
          get :show,
              category: 'foo',
              file: 'bar',
              format: :png
          expect(response).to be_not_found
        end
      end
    end

    context 'for other formats' do
      it 'always renders not found' do
        get :show,
            category: 'ssh',
            file: 'README',
            format: :foo
        expect(response).to be_not_found
      end
    end
  end
end
