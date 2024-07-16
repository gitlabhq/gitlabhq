import { GlEmptyState, GlLoadingIcon, GlTableLite } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import waitForPromises from 'helpers/wait_for_promises';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

import BulkImportsHistoryApp from '~/pages/import/bulk_imports/history/components/bulk_imports_history_app.vue';
import ImportStatus from '~/import_entities/import_groups/components/import_status.vue';
import ImportStats from '~/import_entities/components/import_stats.vue';
import PaginationBar from '~/vue_shared/components/pagination_bar/pagination_bar.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

describe('BulkImportsHistoryApp', () => {
  const BULK_IMPORTS_API_URL = '/api/v4/bulk_imports/entities';

  const DEFAULT_HEADERS = {
    'x-page': 1,
    'x-per-page': 20,
    'x-next-page': 2,
    'x-total': 22,
    'x-total-pages': 2,
    'x-prev-page': null,
  };
  const DUMMY_RESPONSE = [
    {
      id: 361,
      bulk_import_id: 1,
      status: 'finished',
      entity_type: 'group',
      source_full_path: 'top-level-group-12',
      destination_full_path: 'h5bp/top-level-group-12',
      destination_name: 'top-level-group-12',
      destination_slug: 'top-level-group-12',
      destination_namespace: 'h5bp',
      created_at: '2021-07-08T10:03:44.743Z',
      has_failures: false,
      failures: [],
      stats: {
        labels: {
          fetched: 10,
          imported: 9,
        },
      },
    },
    {
      id: 843,
      bulk_import_id: 2,
      status: 'failed',
      entity_type: 'project',
      source_full_path: 'autodevops-demo',
      destination_name: 'autodevops-demo',
      destination_slug: 'autodevops-demo',
      destination_full_path: 'some-group/autodevops-demo',
      destination_namespace: 'flightjs',
      parent_id: null,
      namespace_id: null,
      project_id: null,
      created_at: '2021-07-13T12:52:26.664Z',
      updated_at: '2021-07-13T13:34:49.403Z',
      has_failures: true,
      failures: [
        {
          pipeline_class: 'BulkImports::Groups::Pipelines::GroupPipeline',
          pipeline_step: 'loader',
          exception_class: 'ActiveRecord::RecordNotUnique',
          correlation_id_value: '01FAFYSYZ7XPF3P9NSMTS693SZ',
          created_at: '2021-07-13T13:34:49.344Z',
        },
      ],
      stats: {},
    },
  ];

  let wrapper;
  let mock;
  const mockDetailsPath = '/import/:id/history/:entity_id/failures';
  const mockRealtimeChangesPath = '/import/realtime_changes.json';

  function createComponent({ shallow = true, props = {} } = {}) {
    const mountFn = shallow ? shallowMount : mount;
    wrapper = mountFn(BulkImportsHistoryApp, {
      provide: {
        detailsPath: mockDetailsPath,
        realtimeChangesPath: mockRealtimeChangesPath,
      },
      propsData: {
        ...props,
      },
    });
  }

  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);
  const findPaginationBar = () => wrapper.findComponent(PaginationBar);
  const findTableRow = (index) => wrapper.findAll('tbody tr').at(index);
  const findImportStatusAt = (index) => wrapper.findAllComponents(ImportStatus).at(index);

  beforeEach(() => {
    gon.api_version = 'v4';

    mock = new MockAdapter(axios);
    mock.onGet(BULK_IMPORTS_API_URL).reply(HTTP_STATUS_OK, DUMMY_RESPONSE, DEFAULT_HEADERS);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('general behavior', () => {
    it('renders loading state when loading', () => {
      createComponent();
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('renders empty state when no data is available', async () => {
      mock.onGet(BULK_IMPORTS_API_URL).reply(HTTP_STATUS_OK, [], DEFAULT_HEADERS);
      createComponent();
      await waitForPromises();

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
    });

    it('renders table with data when history is available', async () => {
      createComponent();
      await waitForPromises();

      const table = wrapper.findComponent(GlTableLite);
      expect(table.exists()).toBe(true);
      // can't use .props() or .attributes() here
      expect(table.vm.$attrs.items).toHaveLength(DUMMY_RESPONSE.length);
    });

    it('changes page when requested by pagination bar', async () => {
      const NEW_PAGE = 4;

      createComponent();
      await waitForPromises();
      mock.resetHistory();

      findPaginationBar().vm.$emit('set-page', NEW_PAGE);
      await waitForPromises();

      expect(mock.history.get.length).toBe(1);
      expect(mock.history.get[0].params).toStrictEqual(expect.objectContaining({ page: NEW_PAGE }));
    });
  });

  describe('when id prop is present', () => {
    const mockId = '2';

    beforeEach(async () => {
      createComponent({
        props: {
          id: mockId,
        },
      });
      await waitForPromises();
    });

    it('makes a request to bulk_import_history endpoint', () => {
      expect(mock.history.get.length).toBe(1);
      expect(mock.history.get[0].url).toBe(`/api/v4/bulk_imports/${mockId}/entities`);
      expect(mock.history.get[0].params).toStrictEqual({
        page: 1,
        per_page: 20,
      });
    });
  });

  it('changes page size when requested by pagination bar', async () => {
    const NEW_PAGE_SIZE = 4;

    createComponent();
    await waitForPromises();
    mock.resetHistory();

    findPaginationBar().vm.$emit('set-page-size', NEW_PAGE_SIZE);
    await waitForPromises();

    expect(mock.history.get.length).toBe(1);
    expect(mock.history.get[0].params).toStrictEqual(
      expect.objectContaining({ per_page: NEW_PAGE_SIZE }),
    );
  });

  it('resets page to 1 when page size is changed', async () => {
    const NEW_PAGE_SIZE = 4;

    createComponent();
    await waitForPromises();
    findPaginationBar().vm.$emit('set-page', 2);
    await waitForPromises();
    mock.resetHistory();

    findPaginationBar().vm.$emit('set-page-size', NEW_PAGE_SIZE);
    await waitForPromises();

    expect(mock.history.get.length).toBe(1);
    expect(mock.history.get[0].params).toStrictEqual(
      expect.objectContaining({ per_page: NEW_PAGE_SIZE, page: 1 }),
    );
  });

  it('sets up the local storage sync correctly', async () => {
    const NEW_PAGE_SIZE = 4;

    createComponent();
    await waitForPromises();
    mock.resetHistory();

    findPaginationBar().vm.$emit('set-page-size', NEW_PAGE_SIZE);
    await waitForPromises();

    expect(findLocalStorageSync().props('value')).toBe(NEW_PAGE_SIZE);
  });

  describe('table rendering', () => {
    beforeEach(async () => {
      createComponent({ shallow: false });
      await waitForPromises();
    });

    it('renders link to destination_full_path for destination group', () => {
      expect(wrapper.find('tbody tr a').attributes().href).toBe(
        `/${DUMMY_RESPONSE[0].destination_full_path}`,
      );
    });

    it('renders destination as text when destination_full_path is not defined', async () => {
      const RESPONSE = [{ ...DUMMY_RESPONSE[0], destination_full_path: null }];

      mock.onGet(BULK_IMPORTS_API_URL).reply(HTTP_STATUS_OK, RESPONSE, DEFAULT_HEADERS);
      createComponent({ shallow: false });
      await waitForPromises();

      expect(wrapper.find('tbody tr a').exists()).toBe(false);
      expect(wrapper.find('tbody tr span').text()).toBe(
        `${DUMMY_RESPONSE[0].destination_namespace}/${DUMMY_RESPONSE[0].destination_slug}/`,
      );
    });

    it('adds slash to group urls', () => {
      expect(wrapper.find('tbody tr a').text()).toBe(`${DUMMY_RESPONSE[0].destination_full_path}/`);
    });

    it('does not prefix project urls with slash', () => {
      expect(wrapper.findAll('tbody tr a').at(1).text()).toBe(
        DUMMY_RESPONSE[1].destination_full_path,
      );
    });

    it('renders finished import status', () => {
      expect(findImportStatusAt(0).text()).toBe('Complete');
    });

    it('renders failed import status with details link', async () => {
      createComponent({
        shallow: false,
      });
      await waitForPromises();

      const failedImportStatus = findImportStatusAt(1);
      const failedImportStatusLink = failedImportStatus.find('a');
      expect(failedImportStatus.text()).toContain('Failed');
      expect(failedImportStatusLink.text()).toBe('Show errors >');
      expect(failedImportStatusLink.attributes('href')).toBe('/import/2/history/843/failures');
    });

    it('renders import stats', () => {
      expect(findTableRow(0).findComponent(ImportStats).props('stats')).toEqual(
        DUMMY_RESPONSE[0].stats,
      );
    });

    it('does not render import stats when not available', () => {
      expect(findTableRow(1).findComponent(ImportStats).exists()).toBe(false);
    });
  });

  describe('status polling', () => {
    describe('when there are no isImporting imports', () => {
      it('does not start polling', async () => {
        createComponent({ shallow: false });
        await waitForPromises();

        expect(mock.history.get.map((x) => x.url)).toEqual([BULK_IMPORTS_API_URL]);
      });
    });

    describe('when there are isImporting imports', () => {
      const mockCreatedImport = {
        id: 3,
        bulk_import_id: 3,
        status: 'created',
        entity_type: 'group',
        source_full_path: 'top-level-group-12',
        destination_full_path: 'h5bp/top-level-group-12',
        destination_name: 'top-level-group-12',
        destination_namespace: 'h5bp',
        created_at: '2021-07-08T10:03:44.743Z',
        failures: [],
      };
      const mockImportChanges = [{ id: 3, status_name: 'finished' }];
      const pollInterval = 1;

      beforeEach(async () => {
        const RESPONSE = [mockCreatedImport, ...DUMMY_RESPONSE];
        const POLL_HEADERS = { 'poll-interval': pollInterval };

        mock.onGet(BULK_IMPORTS_API_URL).reply(HTTP_STATUS_OK, RESPONSE, DEFAULT_HEADERS);
        mock.onGet(mockRealtimeChangesPath).replyOnce(HTTP_STATUS_OK, [], POLL_HEADERS);
        mock
          .onGet(mockRealtimeChangesPath)
          .replyOnce(HTTP_STATUS_OK, mockImportChanges, POLL_HEADERS);

        createComponent({ shallow: false });

        await waitForPromises();
      });

      it('starts polling for realtime changes', () => {
        jest.advanceTimersByTime(pollInterval);

        expect(mock.history.get.map((x) => x.url)).toEqual([
          BULK_IMPORTS_API_URL,
          mockRealtimeChangesPath,
        ]);
        expect(findTableRow(0).text()).toContain('Pending');
      });

      it('stops polling when import is finished', async () => {
        jest.advanceTimersByTime(pollInterval);
        await waitForPromises();
        // Wait an extra interval to make sure we've stopped polling
        jest.advanceTimersByTime(pollInterval);
        await waitForPromises();

        expect(mock.history.get.map((x) => x.url)).toEqual([
          BULK_IMPORTS_API_URL,
          mockRealtimeChangesPath,
          mockRealtimeChangesPath,
        ]);
        expect(findTableRow(0).text()).toContain('Complete');
      });
    });
  });
});
