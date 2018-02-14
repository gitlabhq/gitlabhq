require 'spec_helper'

describe 'Deprecated boards paths' do
  let!(:group) { create(:group, name: 'gitlabhq') }

  context 'when no group called boards exists' do
    it 'redirects to boards page' do
      get('/groups/gitlabhq/boards')

      expect(response).to redirect_to('/groups/gitlabhq/-/boards')
    end

    it 'redirects to the boards page with additional params' do
      get('/groups/gitlabhq/boards/1?foo=bar')

      expect(response).to redirect_to(group_board_path(group, 1, foo: 'bar'))
    end
  end

  context 'when a group called boards exists', :nested_groups do
    before do
      create(:group, name: 'boards', parent: group)
    end

    it 'does not redirect to the main boards page' do
      get('/groups/gitlabhq/boards')

      expect(response).to have_gitlab_http_status(200)
    end

    it 'does not redirect to the boards page with additional params' do
      get('/groups/gitlabhq/boards/-/issues')

      expect(response).to have_gitlab_http_status(200)
    end

    it 'redirects to the boards page with additional params if there is no matching route on the subgroup' do
      get('/groups/gitlabhq/boards/1?foo=bar')

      expect(response).to redirect_to(group_board_path(group, 1, foo: 'bar'))
    end
  end
end
