import MockAdapter from 'axios-mock-adapter';
import { setActivePinia, createPinia } from 'pinia';

import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_OK,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_NO_CONTENT,
  HTTP_STATUS_CREATED,
} from '~/lib/utils/http_status';
import { createAlert, VARIANT_INFO } from '~/alert';
import { useServiceAccounts } from '~/service_accounts/stores/service_accounts';

const mockAlertDismiss = jest.fn();
jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

describe('useAccessTokens store', () => {
  let store;
  const mockAxios = new MockAdapter(axios);
  const url = 'https://gitlab.example.com/api/v4/groups/33/service_accounts';
  const params = { page: 1, perPage: 8 };
  const headers = {
    'X-Page': 1,
    'X-Per-Page': 8,
    'X-Total': 1,
  };

  const values = {
    username: 'service_account_group_33_71573d686886d1e49b90c9705f4f534b',
    name: 'Service account user',
  };

  const serviceAccounts = [
    {
      id: 85,
      ...values,
    },
  ];

  beforeEach(() => {
    mockAxios.reset();
    setActivePinia(createPinia());
    store = useServiceAccounts();
  });

  describe('initial state', () => {
    it('has correct values', () => {
      expect(store.alert).toBeNull();
      expect(store.serviceAccounts).toEqual([]);
      expect(store.serviceAccountCount).toBe(0);
      expect(store.busy).toBe(false);
      expect(store.url).toBe('');
      expect(store.page).toBe(1);
      expect(store.perPage).toBe(8);
      expect(store.deleteType).toBeNull();
      expect(store.createEditType).toBeNull();
      expect(store.createEditError).toBeNull();
    });
  });

  describe('actions', () => {
    describe('fetchServiceAccounts', () => {
      it('sets busy to true when fetching', () => {
        store.fetchServiceAccounts(url, params);

        expect(store.busy).toBe(true);
      });

      it('calls clearAlert', () => {
        store.clearAlert = jest.fn();
        expect(store.clearAlert).toHaveBeenCalledTimes(0);
        store.fetchServiceAccounts(url, params);

        expect(store.clearAlert).toHaveBeenCalledTimes(1);
      });

      it('fetches the service accounts with the correct params', async () => {
        await store.fetchServiceAccounts(url, { page: 2 });

        expect(mockAxios.history.get[0]).toEqual(
          expect.objectContaining({
            url,
            params: {
              page: 2,
              per_page: 8,
              orderBy: 'name',
            },
          }),
        );
      });

      it('updates service accounts after fetching', async () => {
        mockAxios.onGet().replyOnce(HTTP_STATUS_OK, serviceAccounts, headers);
        await store.fetchServiceAccounts(url, params);

        expect(store.serviceAccounts).toHaveLength(1);
        expect(store.busy).toBe(false);
      });

      it('shows an alert if an error occurs while fetching', async () => {
        mockAxios.onGet().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        await store.fetchServiceAccounts(url, params);

        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while fetching the service accounts.',
        });
        expect(store.busy).toBe(false);
      });
    });

    describe('setServiceAccount', () => {
      it('sets the service account', () => {
        store.setServiceAccount(serviceAccounts[0]);

        expect(store.serviceAccount).toMatchObject(serviceAccounts[0]);
      });
    });

    describe('setDeleteType', () => {
      it('sets the service account', () => {
        store.setDeleteType('hard');

        expect(store.deleteType).toBe('hard');
      });
    });

    describe('setCreateEditType', () => {
      it('sets the createEditType', () => {
        store.setCreateEditType('create');

        expect(store.createEditType).toBe('create');
      });
    });

    describe('clear alert', () => {
      it('clears the alert', () => {
        store.alert = createAlert({ message: 'dummy' });
        store.createEditError = 'my error';
        store.clearAlert();

        expect(store.alert).toBe(null);
        expect(store.createEditError).toBe(null);
      });
    });

    describe('createServiceAccount', () => {
      it('sets busy to true', () => {
        store.createServiceAccount(url, values);

        expect(store.busy).toBe(true);
      });

      it('calls clearAlert', () => {
        store.clearAlert = jest.fn();
        expect(store.clearAlert).toHaveBeenCalledTimes(0);
        store.fetchServiceAccounts(url, params);

        expect(store.clearAlert).toHaveBeenCalledTimes(1);
      });

      it('calls the create endpoint with the correct params', async () => {
        await store.createServiceAccount(url, values);

        expect(mockAxios.history.post[0]).toEqual(
          expect.objectContaining({
            url,
            data: '{"username":"service_account_group_33_71573d686886d1e49b90c9705f4f534b","name":"Service account user"}',
          }),
        );
      });

      it('calls the create endpoint with the correct params when using a user provided email', async () => {
        await store.createServiceAccount(url, { ...values, email: 'test@gitlab.com' });

        expect(mockAxios.history.post[0]).toEqual(
          expect.objectContaining({
            url,
            data: '{"username":"service_account_group_33_71573d686886d1e49b90c9705f4f534b","name":"Service account user","email":"test@gitlab.com"}',
          }),
        );
      });

      it('shows alert', async () => {
        mockAxios.onPost().replyOnce(HTTP_STATUS_CREATED);
        await store.createServiceAccount(url, values);

        expect(createAlert).toHaveBeenCalledWith({
          message: 'The service account was created.',
          variant: VARIANT_INFO,
        });
      });

      it('reset the createEditType', async () => {
        store.createEditType = 'create';
        mockAxios.onPost().replyOnce(HTTP_STATUS_CREATED);
        await store.createServiceAccount(url, values);

        expect(store.createEditType).toBe(null);
      });

      it('fetches service accounts', async () => {
        mockAxios.onPost().replyOnce(HTTP_STATUS_CREATED);
        mockAxios.onGet().replyOnce(HTTP_STATUS_OK, serviceAccounts, headers);
        await store.createServiceAccount(url, values);

        expect(store.serviceAccounts).toHaveLength(1);
      });

      it('does not clear the alert on fetching service accounts', async () => {
        mockAxios.onPost().replyOnce(HTTP_STATUS_CREATED);
        mockAxios.onGet().replyOnce(HTTP_STATUS_OK, serviceAccounts, headers);
        await store.createServiceAccount(url, values);

        expect(mockAlertDismiss).toHaveBeenCalledTimes(0);
      });

      it('sets the createEditError', async () => {
        mockAxios.onPost().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        await store.createServiceAccount(url, values);

        expect(store.createEditError).toBe('An error occurred creating the service account.');
      });

      it('reset the busy state', async () => {
        await store.createServiceAccount(url, values);

        expect(store.busy).toBe(false);
      });
    });

    describe('editServiceAccount', () => {
      beforeEach(() => {
        [store.serviceAccount] = serviceAccounts;
      });

      it('sets busy to true', () => {
        store.editServiceAccount(url, values, false);

        expect(store.busy).toBe(true);
      });

      it('calls clearAlert', () => {
        store.clearAlert = jest.fn();
        expect(store.clearAlert).toHaveBeenCalledTimes(0);
        store.fetchServiceAccounts(url, params);

        expect(store.clearAlert).toHaveBeenCalledTimes(1);
      });

      it('calls the edit endpoint with the correct params', async () => {
        await store.editServiceAccount(url, values);

        expect(mockAxios.history.patch[0]).toEqual(
          expect.objectContaining({
            url: `${url}/85`,
            data: '{"username":"service_account_group_33_71573d686886d1e49b90c9705f4f534b","name":"Service account user"}',
          }),
        );

        expect(mockAxios.history.patch[0]).toEqual(
          expect.not.objectContaining({
            email: null,
          }),
        );
      });

      it('calls the edit endpoint with the correct params when using a user provided email', async () => {
        await store.editServiceAccount(url, { ...values, email: 'test@gitlab.com' });

        expect(mockAxios.history.patch[0]).toEqual(
          expect.objectContaining({
            url: `${url}/85`,
            data: '{"username":"service_account_group_33_71573d686886d1e49b90c9705f4f534b","name":"Service account user","email":"test@gitlab.com"}',
          }),
        );
      });

      it('shows alert', async () => {
        mockAxios.onPatch().replyOnce(HTTP_STATUS_OK);
        await store.editServiceAccount(url, values);

        expect(createAlert).toHaveBeenCalledWith({
          message: 'The service account was updated.',
          variant: VARIANT_INFO,
        });
      });

      it('reset the createEditType', async () => {
        store.createEditType = 'edit';
        mockAxios.onPatch().replyOnce(HTTP_STATUS_OK);
        await store.editServiceAccount(url, values);

        expect(store.createEditType).toBe(null);
      });

      it('fetches service accounts', async () => {
        mockAxios.onPatch().replyOnce(HTTP_STATUS_OK);
        mockAxios.onGet().replyOnce(HTTP_STATUS_OK, serviceAccounts, headers);
        await store.editServiceAccount(url, values);

        expect(store.serviceAccounts).toHaveLength(1);
      });

      it('does not clear the alert on fetching service accounts', async () => {
        mockAxios.onPatch().replyOnce(HTTP_STATUS_OK);
        mockAxios.onGet().replyOnce(HTTP_STATUS_OK, serviceAccounts, headers);
        await store.editServiceAccount(url, values);

        expect(mockAlertDismiss).toHaveBeenCalledTimes(0);
      });

      it('sets the createEditError', async () => {
        mockAxios.onPatch().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        await store.editServiceAccount(url, values);

        expect(store.createEditError).toBe('An error occurred updating the service account.');
      });

      it('reset the busy state', async () => {
        await store.editServiceAccount(url, values);

        expect(store.busy).toBe(false);
      });
    });

    describe('deleteUser', () => {
      beforeEach(() => {
        [store.serviceAccount] = serviceAccounts;
        store.deleteType = 'hard';
      });

      it('sets busy to true', () => {
        store.deleteUser(url);

        expect(store.busy).toBe(true);
      });

      it('calls clearAlert', () => {
        store.clearAlert = jest.fn();
        expect(store.clearAlert).toHaveBeenCalledTimes(0);
        store.fetchServiceAccounts(url, params);

        expect(store.clearAlert).toHaveBeenCalledTimes(1);
      });

      it('calls the delete endpoint with the correct params', async () => {
        await store.deleteUser(url);

        expect(mockAxios.history.delete[0]).toEqual(
          expect.objectContaining({ url: `${url}/85`, data: '{"id":85,"hard_delete":true}' }),
        );
      });

      it('shows alert', async () => {
        mockAxios.onDelete().replyOnce(HTTP_STATUS_NO_CONTENT);
        await store.deleteUser(url);

        expect(createAlert).toHaveBeenCalledWith({
          message: 'The service account is being deleted.',
          variant: VARIANT_INFO,
        });
      });

      it('fetches service accounts', async () => {
        mockAxios.onDelete().replyOnce(HTTP_STATUS_NO_CONTENT);
        mockAxios.onGet().replyOnce(HTTP_STATUS_OK, serviceAccounts, headers);
        await store.deleteUser(url);

        expect(store.serviceAccounts).toHaveLength(1);
      });

      it('does not clear the alert on fetching service accounts', async () => {
        mockAxios.onDelete().replyOnce(HTTP_STATUS_NO_CONTENT);
        mockAxios.onGet().replyOnce(HTTP_STATUS_OK, serviceAccounts, headers);
        await store.deleteUser(url);

        expect(mockAlertDismiss).toHaveBeenCalledTimes(0);
      });

      it('shows alert on error', async () => {
        mockAxios.onDelete().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        await store.deleteUser(url);

        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while deleting the service account.',
        });
      });

      it('reset the deleteType', async () => {
        await store.deleteUser(url);

        expect(store.deleteType).toBeNull();
      });

      it('reset the busy state', async () => {
        await store.deleteUser(url);

        expect(store.busy).toBe(false);
      });
    });
  });
});
