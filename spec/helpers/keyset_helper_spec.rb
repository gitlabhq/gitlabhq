# frozen_string_literal: true
require 'spec_helper'

RSpec.describe KeysetHelper, type: :controller do
  controller(Admin::UsersController) do
    def index
      @users = User
        .where(admin: false)
        .order(id: :desc)
        .keyset_paginate(cursor: params[:cursor], per_page: 2)

      render inline: "<%= keyset_paginate @users %>", layout: false # rubocop: disable Rails/RenderInline
    end
  end

  render_views

  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  context 'with admin mode', :enable_admin_mode do
    context 'when no users are present' do
      it 'does not render pagination links' do
        get :index

        expect(response.body).not_to include(s_('Pagination|First'))
        expect(response.body).not_to include(s_('Pagination|Prev'))
        expect(response.body).not_to include(s_('Pagination|Next'))
        expect(response.body).not_to include(s_('Pagination|Last'))
      end
    end

    context 'when one user is present' do
      before do
        create(:user)
      end

      it 'does not render pagination links' do
        get :index

        expect(response.body).not_to include(s_('Pagination|First'))
        expect(response.body).not_to include(s_('Pagination|Prev'))
        expect(response.body).not_to include(s_('Pagination|Next'))
        expect(response.body).not_to include(s_('Pagination|Last'))
      end
    end

    context 'when more users are present' do
      let_it_be(:users) { create_list(:user, 5) }

      let(:paginator) { User.where(admin: false).order(id: :desc).keyset_paginate(per_page: 2) }

      context 'when on the first page' do
        it 'renders the next and last links' do
          get :index

          expect(response.body).not_to include(s_('Pagination|First'))
          expect(response.body).not_to include(s_('Pagination|Prev'))
          expect(response.body).to include(s_('Pagination|Next'))
          expect(response.body).to include(s_('Pagination|Last'))
        end
      end

      context 'when at the last page' do
        it 'renders the prev and first links' do
          cursor = paginator.cursor_for_last_page

          get :index, params: { cursor: cursor }

          expect(response.body).to include(s_('Pagination|First'))
          expect(response.body).to include(s_('Pagination|Prev'))
          expect(response.body).not_to include(s_('Pagination|Next'))
          expect(response.body).not_to include(s_('Pagination|Last'))
        end
      end

      context 'when at the second page' do
        it 'renders all links' do
          cursor = paginator.cursor_for_next_page

          get :index, params: { cursor: cursor }

          expect(response.body).to include(s_('Pagination|First'))
          expect(response.body).to include(s_('Pagination|Prev'))
          expect(response.body).to include(s_('Pagination|Next'))
          expect(response.body).to include(s_('Pagination|Last'))
        end
      end
    end
  end
end
