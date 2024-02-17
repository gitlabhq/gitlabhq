import { mount, shallowMount } from '@vue/test-utils';
import { GlEmptyState, GlLoadingIcon, GlTable } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import { createAlert } from '~/alert';
import waitForPromises from 'helpers/wait_for_promises';

import PaginationBar from '~/vue_shared/components/pagination_bar/pagination_bar.vue';
import ImportDetailsTable from '~/import/details/components/import_details_table.vue';
import { mockImportFailures, mockHeaders } from '../mock_data';

jest.mock('~/alert');

describe('Import details table', () => {
  let wrapper;
  let mock;

  const mockFields = [
    {
      key: 'type',
      label: 'Type',
    },
    {
      key: 'title',
      label: 'Title',
    },
  ];

  const createComponent = ({ mountFn = shallowMount, props = {}, provide = {} } = {}) => {
    wrapper = mountFn(ImportDetailsTable, {
      propsData: {
        fields: mockFields,
        ...props,
      },
      provide,
    });
  };

  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findGlTable = () => wrapper.findComponent(GlTable);
  const findGlTableRows = () => findGlTable().find('tbody').findAll('tr');
  const findGlEmptyState = () => findGlTable().findComponent(GlEmptyState);
  const findPaginationBar = () => wrapper.findComponent(PaginationBar);

  describe('template', () => {
    describe('when no items are available', () => {
      it('renders table with empty state', () => {
        createComponent({ mountFn: mount });

        expect(findGlEmptyState().text()).toBe(ImportDetailsTable.i18n.emptyText);
      });

      it('does not render pagination', () => {
        createComponent();

        expect(findPaginationBar().exists()).toBe(false);
      });
    });
  });

  describe('fetching failures from API', () => {
    const mockImportFailuresPath = '/failures';

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('when request is successful', () => {
      beforeEach(() => {
        mock.onGet(mockImportFailuresPath).reply(HTTP_STATUS_OK, mockImportFailures, mockHeaders);

        createComponent({
          mountFn: mount,
          provide: {
            failuresPath: mockImportFailuresPath,
          },
        });
      });

      it('renders loading icon', () => {
        expect(findGlLoadingIcon().exists()).toBe(true);
      });

      it('does not render loading icon after fetch', async () => {
        await waitForPromises();

        expect(findGlLoadingIcon().exists()).toBe(false);
      });

      it('sets items and pagination info', async () => {
        await waitForPromises();

        expect(findGlTableRows().length).toBe(mockImportFailures.length);
        expect(findPaginationBar().props('pageInfo')).toMatchObject({
          page: mockHeaders['x-page'],
          perPage: mockHeaders['x-per-page'],
          total: mockHeaders['x-total'],
          totalPages: mockHeaders['x-total-pages'],
        });
      });
    });

    describe('when request fails', () => {
      beforeEach(() => {
        mock.onGet(mockImportFailuresPath).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        createComponent({
          provide: {
            failuresPath: mockImportFailuresPath,
          },
        });
      });

      it('displays an error', async () => {
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: ImportDetailsTable.i18n.fetchErrorMessage,
        });
      });
    });

    describe('when bulk_import is true', () => {
      const mockId = '144';
      const mockEntityId = '68';

      beforeEach(() => {
        gon.api_version = 'v4';

        mock
          .onGet(`/api/v4/bulk_imports/${mockId}/entities/${mockEntityId}/failures`)
          .reply(HTTP_STATUS_OK, mockImportFailures, mockHeaders);

        createComponent({
          mountFn: mount,
          props: {
            bulkImport: true,
            id: mockId,
            entityId: mockEntityId,
          },
        });
      });

      it('renders loading icon', () => {
        expect(findGlLoadingIcon().exists()).toBe(true);
      });

      it('does not render loading icon after fetch', async () => {
        await waitForPromises();

        expect(findGlLoadingIcon().exists()).toBe(false);
      });

      it('sets items and pagination info', async () => {
        await waitForPromises();

        expect(findGlTableRows().length).toBe(mockImportFailures.length);
        expect(findPaginationBar().props('pageInfo')).toMatchObject({
          page: mockHeaders['x-page'],
          perPage: mockHeaders['x-per-page'],
          total: mockHeaders['x-total'],
          totalPages: mockHeaders['x-total-pages'],
        });
      });
    });
  });
});
