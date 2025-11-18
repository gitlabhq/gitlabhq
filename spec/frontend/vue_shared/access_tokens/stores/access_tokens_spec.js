import MockAdapter from 'axios-mock-adapter';
import { setActivePinia, createPinia } from 'pinia';
import { useAccessTokens } from '~/vue_shared/access_tokens/stores/access_tokens';
import { update15DaysFromNow } from '~/vue_shared/access_tokens/utils';
import { createAlert } from '~/alert';
import { smoothScrollTop } from '~/lib/utils/scroll_utils';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_NO_CONTENT,
  HTTP_STATUS_OK,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
} from '~/lib/utils/http_status';
import { DEFAULT_SORT } from '~/access_tokens/constants';

const mockAlertDismiss = jest.fn();
jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

jest.mock('~/vue_shared/access_tokens/utils', () => ({
  ...jest.requireActual('~/vue_shared/access_tokens/utils'),
  update15DaysFromNow: jest.fn(),
}));

jest.mock('~/lib/utils/scroll_utils');

describe('useAccessTokens store', () => {
  let store;

  beforeEach(() => {
    setActivePinia(createPinia());
    store = useAccessTokens();
  });

  describe('initial state', () => {
    it('has an empty list of access tokens', () => {
      expect(store.alert).toBe(null);
      expect(store.busy).toBe(false);
      expect(store.filters).toEqual([]);
      expect(store.id).toBe(null);
      expect(store.page).toBe(1);
      expect(store.perPage).toBe(null);
      expect(store.showCreateForm).toBe(false);
      expect(store.token).toEqual(null);
      expect(store.tokens).toEqual([]);
      expect(store.total).toBe(0);
      expect(store.urlCreate).toBe('');
      expect(store.urlRevoke).toBe('');
      expect(store.urlRotate).toBe('');
      expect(store.urlShow).toBe('');
      expect(store.sorting).toEqual(DEFAULT_SORT);
      expect(store.statistics).toEqual([]);
    });
  });

  describe('actions', () => {
    const mockAxios = new MockAdapter(axios);
    const filters = ['dummy'];
    const id = 235;
    const page = 1;
    const sorting = DEFAULT_SORT;
    const urlCreate =
      'http://localhost/api/v4/groups/1/service_accounts/:id/personal_access_tokens';
    const urlRevoke =
      'http://localhost/api/v4/groups/2/service_accounts/:id/personal_access_tokens';
    const urlRotate =
      'http://localhost/api/v4/groups/3/service_accounts/:id/personal_access_tokens';
    const urlShow = 'http://localhost/api/v4/personal_access_tokens?user_id=:id';

    const headers = {
      'X-Page': 1,
      'X-Per-Page': 20,
      'X-Total': 1,
    };

    beforeEach(() => {
      mockAxios.reset();
    });

    describe('createToken', () => {
      const name = 'dummy-name';
      const description = 'dummy-description';
      const expiresAt = '2020-01-01';
      const scopes = ['dummy-scope'];

      beforeEach(() => {
        store.setup({ filters, id, page, sorting, urlCreate, urlShow });
      });

      it('dismisses any existing alert', () => {
        store.alert = createAlert({ message: 'dummy' });
        store.fetchTokens();

        expect(mockAlertDismiss).toHaveBeenCalledTimes(1);
      });

      it('sets busy to true when revoking', () => {
        store.createToken({ name, description, expiresAt, scopes });

        expect(store.busy).toBe(true);
      });

      it('creates the token', async () => {
        await store.createToken({ name, description, expiresAt, scopes });

        expect(mockAxios.history.post).toHaveLength(1);
        expect(mockAxios.history.post[0]).toEqual(
          expect.objectContaining({
            data: '{"name":"dummy-name","description":"dummy-description","expires_at":"2020-01-01","scopes":["dummy-scope"]}',
            url: 'http://localhost/api/v4/groups/1/service_accounts/235/personal_access_tokens',
          }),
        );
      });

      it('hides the token creation form', async () => {
        mockAxios.onPost().replyOnce(HTTP_STATUS_OK, { token: 'new-token' });
        store.showCreateForm = true;
        await store.createToken({ name, description, expiresAt, scopes });

        expect(store.showCreateForm).toBe(false);
      });

      it('scrolls to the top', async () => {
        mockAxios.onPost().replyOnce(HTTP_STATUS_OK, { token: 'new-token' });
        await store.createToken({ name, description, expiresAt, scopes });

        expect(smoothScrollTop).toHaveBeenCalledTimes(1);
      });

      it('updates tokens and sets busy to false after fetching', async () => {
        mockAxios.onPost().replyOnce(HTTP_STATUS_OK, { token: 'new-token' });
        mockAxios.onGet().replyOnce(HTTP_STATUS_OK, [{ active: true, name: 'Token' }], headers);
        await store.createToken({ name, description, expiresAt, scopes });

        expect(store.tokens).toHaveLength(1);
        expect(store.busy).toBe(false);
      });

      it('shows an alert if an error occurs while revoking', async () => {
        mockAxios.onPost().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        await store.createToken({ name, description, expiresAt, scopes });

        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while creating the token.',
          renderMessageHTML: true,
        });
        expect(store.busy).toBe(false);
      });

      it('shows an alert if an error occurs while fetching', async () => {
        mockAxios.onPost().replyOnce(HTTP_STATUS_OK, { token: 'new-token' });
        mockAxios.onGet().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        await store.createToken({ name, description, expiresAt, scopes });

        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while fetching the tokens.',
        });
        expect(store.busy).toBe(false);
      });

      it('uses correct params in the fetch', async () => {
        mockAxios.onPost().replyOnce(HTTP_STATUS_OK, { token: 'new-token' });
        mockAxios.onGet().replyOnce(HTTP_STATUS_OK, [{ active: true, name: 'Token' }], headers);
        store.setPage(2);
        store.setFilters(['my token']);
        await store.createToken({ name, description, expiresAt, scopes });

        expect(mockAxios.history.get).toHaveLength(1);
        expect(mockAxios.history.get[0]).toEqual(
          expect.objectContaining({
            params: {
              page: 1,
              sort: 'expires_asc',
              search: 'my token',
            },
          }),
        );
      });
    });

    describe('fetchStatistics', () => {
      const title = 'Active tokens';
      const tooltipTitle = 'Filter for active tokens';
      beforeEach(() => {
        store.setup({ filters, id, page, sorting, urlShow });
        update15DaysFromNow.mockReturnValueOnce([{ title, tooltipTitle, filters }]);
      });

      it('uses correct params in the fetch', async () => {
        await store.fetchStatistics();

        expect(mockAxios.history.get).toHaveLength(1);
        expect(mockAxios.history.get[0]).toEqual(
          expect.objectContaining({
            url: 'http://localhost/api/v4/personal_access_tokens?user_id=235',
            params: {
              page: 1,
              sort: 'expires_asc',
              search: 'dummy',
            },
          }),
        );
      });

      it('fetches all statistics successfully and updates the store', async () => {
        mockAxios.onGet().replyOnce(HTTP_STATUS_OK, [], headers);
        await store.fetchStatistics();

        expect(store.statistics).toMatchObject([{ title, tooltipTitle, filters, value: 1 }]);
      });

      it('shows an alert if an error occurs while fetching', async () => {
        mockAxios.onGet().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        await store.fetchStatistics();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'Failed to fetch statistics.',
        });
      });

      it('does not show an alert if an error is still on view', async () => {
        store.alert = 'dummy';
        mockAxios.onGet().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        await store.fetchStatistics();

        expect(createAlert).toHaveBeenCalledTimes(0);
      });
    });

    describe('fetchTokens', () => {
      beforeEach(() => {
        store.setup({ filters, id, page, sorting, urlShow });
      });

      it('sets busy to true when fetching', () => {
        store.fetchTokens();

        expect(store.busy).toBe(true);
      });

      it('dismisses any existing alert by default', () => {
        store.alert = createAlert({ message: 'dummy' });
        store.fetchTokens();

        expect(mockAlertDismiss).toHaveBeenCalledTimes(1);
      });

      it('does not dismiss existing alert if clearAlert is false', () => {
        store.alert = createAlert({ message: 'dummy' });
        store.fetchTokens({ clearAlert: false });

        expect(mockAlertDismiss).toHaveBeenCalledTimes(0);
      });

      it('updates tokens and sets busy to false after fetching', async () => {
        mockAxios.onGet().replyOnce(HTTP_STATUS_OK, [{ active: true, name: 'Token' }], headers);
        await store.fetchTokens();

        expect(store.tokens).toHaveLength(1);
        expect(store.busy).toBe(false);
      });

      it('shows an alert if an error occurs while fetching', async () => {
        mockAxios.onGet().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        await store.fetchTokens();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while fetching the tokens.',
        });
        expect(store.busy).toBe(false);
      });

      it('uses correct params in the fetch', async () => {
        store.setFilters([
          'my token',
          {
            type: 'state',
            value: { data: 'inactive', operator: '=' },
          },
        ]);
        await store.fetchTokens();

        expect(mockAxios.history.get).toHaveLength(1);
        expect(mockAxios.history.get[0]).toEqual(
          expect.objectContaining({
            url: 'http://localhost/api/v4/personal_access_tokens?user_id=235',
            params: {
              page: 1,
              sort: 'expires_asc',
              state: 'inactive',
              search: 'my token',
            },
          }),
        );
      });
    });

    describe('formateErrors', () => {
      it('returns the error message from the response if present', () => {
        const response = { error: 'An error message' };
        expect(store.formatErrors(response, 'Default message')).toBe('An error message');
      });

      it('returns the first error from the errors array if present', () => {
        const response = { errors: ['First error'] };
        expect(store.formatErrors(response, 'Default message')).toBe('First error');
      });

      it('returns an unordered list of errors from the errors array if multiple errors are present', () => {
        const response = { errors: ['First error', 'Second error'] };
        expect(store.formatErrors(response, 'Default message')).toBe(
          '<ul class="gl-m-0"><li>First error</li><li>Second error</li></ul>',
        );
      });

      it('returns the message from the response if present', () => {
        const response = { message: 'A message' };
        expect(store.formatErrors(response, 'Default message')).toBe('A message');
      });

      it('returns the default message if no specific error is found in the response', () => {
        const response = {};
        expect(store.formatErrors(response, 'Default message')).toBe('Default message');
      });

      it('returns the default message if response is null', () => {
        const response = null;
        expect(store.formatErrors(response, 'Default message')).toBe('Default message');
      });
    });

    describe('revokeToken', () => {
      beforeEach(() => {
        store.setup({ filters, id, page, sorting, urlRevoke, urlShow });
      });

      it('sets busy to true when revoking', () => {
        store.revokeToken(1);

        expect(store.busy).toBe(true);
      });

      it('hides the token creation form', () => {
        store.showCreateForm = true;
        store.revokeToken(1);

        expect(store.showCreateForm).toBe(false);
      });

      it('dismisses any existing alert', () => {
        store.alert = createAlert({ message: 'dummy' });
        store.fetchTokens();

        expect(mockAlertDismiss).toHaveBeenCalledTimes(1);
      });

      it('revokes the token', async () => {
        await store.revokeToken(1);

        expect(mockAxios.history.delete).toHaveLength(1);
        expect(mockAxios.history.delete[0]).toEqual(
          expect.objectContaining({
            url: 'http://localhost/api/v4/groups/2/service_accounts/235/personal_access_tokens/1',
          }),
        );
      });

      it('scrolls to the top', async () => {
        mockAxios.onDelete().replyOnce(HTTP_STATUS_NO_CONTENT);
        await store.revokeToken(1);

        expect(smoothScrollTop).toHaveBeenCalledTimes(1);
      });

      it('shows an alert after successful token revocation', async () => {
        mockAxios.onDelete().replyOnce(HTTP_STATUS_NO_CONTENT);
        mockAxios.onGet().replyOnce(HTTP_STATUS_OK);
        await store.revokeToken(1);

        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          message: 'The token was revoked successfully.',
          variant: 'success',
        });
      });

      it('updates tokens and sets busy to false after fetching', async () => {
        mockAxios.onDelete().replyOnce(HTTP_STATUS_NO_CONTENT);
        mockAxios.onGet().replyOnce(HTTP_STATUS_OK, [{ active: true, name: 'Token' }], headers);
        await store.revokeToken(1);

        expect(store.tokens).toHaveLength(1);
        expect(store.busy).toBe(false);
      });

      it('shows an alert if an error occurs while revoking', async () => {
        mockAxios.onDelete().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        await store.revokeToken(1);

        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while revoking the token.',
          renderMessageHTML: true,
        });
        expect(store.busy).toBe(false);
      });

      it('shows an alert if an error occurs while fetching', async () => {
        mockAxios.onDelete().replyOnce(HTTP_STATUS_NO_CONTENT);
        mockAxios.onGet().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        await store.revokeToken(1);

        expect(createAlert).toHaveBeenCalledTimes(2);
        expect(createAlert).toHaveBeenCalledWith({
          message: 'The token was revoked successfully.',
          variant: 'success',
        });
        // This alert hides the one above.
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while fetching the tokens.',
        });
        expect(store.busy).toBe(false);
      });

      it('uses correct params in the fetch', async () => {
        mockAxios.onDelete().replyOnce(HTTP_STATUS_NO_CONTENT);
        mockAxios.onGet().replyOnce(HTTP_STATUS_OK, [{ active: true, name: 'Token' }], headers);
        store.setPage(2);
        store.setFilters(['my token']);
        await store.revokeToken(1);

        expect(mockAxios.history.get).toHaveLength(1);
        expect(mockAxios.history.get[0]).toEqual(
          expect.objectContaining({
            params: {
              page: 1,
              sort: 'expires_asc',
              search: 'my token',
            },
          }),
        );
      });

      it('hides the new token component', async () => {
        store.token = 'new token';
        mockAxios.onDelete().replyOnce(HTTP_STATUS_NO_CONTENT);
        await store.revokeToken(1);

        expect(store.token).toBeNull();
      });
    });

    describe('rotateToken', () => {
      beforeEach(() => {
        store.setup({ filters, id, page, sorting, urlRotate, urlShow });
      });

      it('sets busy to true when rotating', () => {
        store.rotateToken(1, '2025-01-01');

        expect(store.busy).toBe(true);
      });

      it('hides the token creation form', () => {
        store.showCreateForm = true;
        store.rotateToken(1, '2025-01-01');

        expect(store.showCreateForm).toBe(false);
      });

      it('dismisses any existing alert', () => {
        store.alert = createAlert({ message: 'dummy' });
        store.fetchTokens();

        expect(mockAlertDismiss).toHaveBeenCalledTimes(1);
      });

      it('rotates the token', async () => {
        await store.rotateToken(1, '2025-01-01');

        expect(mockAxios.history.post).toHaveLength(1);
        expect(mockAxios.history.post[0]).toEqual(
          expect.objectContaining({
            data: '{"expires_at":"2025-01-01"}',
            url: 'http://localhost/api/v4/groups/3/service_accounts/235/personal_access_tokens/1/rotate',
          }),
        );
      });

      it('scrolls to the top', async () => {
        mockAxios.onPost().replyOnce(HTTP_STATUS_OK, { token: 'new-token' });
        await store.rotateToken(1, '2025-01-01');

        expect(smoothScrollTop).toHaveBeenCalledTimes(1);
      });

      it('updates tokens and sets busy to false after fetching', async () => {
        mockAxios.onPost().replyOnce(HTTP_STATUS_OK, { token: 'new-token' });
        mockAxios.onGet().replyOnce(HTTP_STATUS_OK, [{ active: true, name: 'Token' }], headers);
        await store.rotateToken(1, '2025-01-01');

        expect(store.tokens).toHaveLength(1);
        expect(store.busy).toBe(false);
      });

      it('shows an alert if an error occurs while rotating', async () => {
        mockAxios.onPost().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        await store.rotateToken(1, '2025-01-01');

        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while rotating the token.',
          renderMessageHTML: true,
        });
        expect(store.busy).toBe(false);
      });

      it('shows an alert if an error occurs while fetching', async () => {
        mockAxios.onPost().replyOnce(HTTP_STATUS_OK, { token: 'new-token' });
        mockAxios.onGet().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        await store.rotateToken(1, '2025-01-01');

        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while fetching the tokens.',
        });
        expect(store.busy).toBe(false);
      });

      it('uses correct params in the fetch', async () => {
        mockAxios.onPost().replyOnce(HTTP_STATUS_OK, { token: 'new-token' });
        mockAxios.onGet().replyOnce(HTTP_STATUS_OK, [{ active: true, name: 'Token' }], headers);
        store.setPage(2);
        store.setFilters(['my token']);
        await store.rotateToken(1, '2025-01-01');

        expect(mockAxios.history.get).toHaveLength(1);
        expect(mockAxios.history.get[0]).toEqual(
          expect.objectContaining({
            params: {
              page: 1,
              sort: 'expires_asc',
              search: 'my token',
            },
          }),
        );
      });
    });

    describe('setFilters', () => {
      it('sets the filters', () => {
        store.setFilters(['my token']);

        expect(store.filters).toEqual(['my token']);
      });
    });

    describe('setPage', () => {
      it('sets the page', () => {
        store.setPage(2);

        expect(store.page).toBe(2);
      });

      it('scrolls to the top', () => {
        store.setPage(2);

        expect(smoothScrollTop).toHaveBeenCalledTimes(1);
      });
    });

    describe('setShowCreateForm', () => {
      it('sets the value', () => {
        store.setShowCreateForm(true);

        expect(store.showCreateForm).toBe(true);
      });
    });

    describe('setToken', () => {
      it('sets the token', () => {
        store.setToken('new-token');

        expect(store.token).toBe('new-token');
      });
    });

    describe('setSorting', () => {
      it('sets the sorting', () => {
        store.setSorting({ isAsc: false, value: 'name' });

        expect(store.sorting).toEqual({ isAsc: false, value: 'name' });
      });
    });

    describe('setup', () => {
      it('sets up the store', () => {
        store.token = 'new token';
        store.setup({
          filters,
          id,
          page,
          showCreateForm: true,
          sorting,
          urlCreate,
          urlRevoke,
          urlRotate,
          urlShow,
        });

        expect(store.filters).toEqual(filters);
        expect(store.id).toBe(id);
        expect(store.page).toBe(page);
        expect(store.showCreateForm).toBe(true);
        expect(store.sorting).toEqual(sorting);
        expect(store.token).toEqual(null);
        expect(store.urlCreate).toBe(urlCreate);
        expect(store.urlRevoke).toBe(urlRevoke);
        expect(store.urlRotate).toBe(urlRotate);
        expect(store.urlShow).toBe(urlShow);
      });
    });
  });

  describe('getters', () => {
    describe('params', () => {
      it('returns correct value', () => {
        store.page = 2;

        expect(store.params).toEqual({ page: 2 });
      });
    });

    describe('sort', () => {
      it('returns correct value', () => {
        expect(store.sort).toBe('expires_asc');

        store.sorting = { value: 'name', isAsc: false };

        expect(store.sort).toBe('name_desc');
      });
    });

    describe('urlParmas', () => {
      it('return correct value', () => {
        store.page = 2;
        store.sorting = { value: 'name', isAsc: false };

        expect(store.urlParams).toEqual({
          page: 2,
          sort: 'name_desc',
        });
      });
    });
  });
});
