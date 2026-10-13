import { GlEmptyState, GlLoadingIcon, GlTableLite } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { createAlert } from '~/alert';
import OfflineTransferExportHistoryApp from '~/import/offline_transfer/export/history/app.vue';
import ExportStatusBadge from '~/import/offline_transfer/export/history/components/export_status_badge.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { mockOfflineExports, mockPurgedExport } from '../../mock_data';

jest.mock('~/alert');

describe('OfflineTransferExportHistoryApp', () => {
  const API_URL = '/api/v4/offline_exports';

  let wrapper;
  let mock;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findTable = () => wrapper.findComponent(GlTableLite);
  const findStatusBadges = () => wrapper.findAllComponents(ExportStatusBadge);
  const findRowCells = (row) => findTable().findAll('tbody tr').at(row).findAll('td');

  const createComponent = ({ mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(OfflineTransferExportHistoryApp);
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    window.gon = { api_version: 'v4', uf_error_prefix: 'UF:' };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('while requesting exports', () => {
    beforeEach(() => {
      mock.onGet(API_URL).reply(HTTP_STATUS_OK, []);
      createComponent();
    });

    it('renders only the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findEmptyState().exists()).toBe(false);
      expect(findTable().exists()).toBe(false);
    });
  });

  describe('when there are no exports', () => {
    beforeEach(async () => {
      mock.onGet(API_URL).reply(HTTP_STATUS_OK, []);
      createComponent();
      await waitForPromises();
    });

    it('renders the empty state', () => {
      expect(findTable().exists()).toBe(false);
      expect(findEmptyState().props('title')).toBe('No history is available yet');
      expect(findEmptyState().props('description')).toBe(
        'Groups exported through offline transfer appear here.',
      );
    });
  });

  describe('when exports exist', () => {
    beforeEach(async () => {
      mock.onGet(API_URL).reply(HTTP_STATUS_OK, mockOfflineExports);
      createComponent({ mountFn: mountExtended });
      await waitForPromises();
    });

    it('requests the maximum page size the API allows', () => {
      expect(mock.history.get[0].params).toEqual({ per_page: 100 });
    });

    it('does not render the empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });

    it('renders a row per export', () => {
      expect(findTable().findAll('tbody tr')).toHaveLength(2);
    });

    it('renders the column headers', () => {
      expect(
        findTable()
          .findAll('thead th')
          .wrappers.map((th) => th.text()),
      ).toEqual(['Destination bucket', 'Export prefix', 'Start date', 'Status']);
    });

    it('renders the bucket and export prefix cells', () => {
      expect(findRowCells(0).at(0).text()).toBe('gitlab-exports');
      expect(findRowCells(0).at(1).text()).toBe('2026-09-11_10-00-00_export_ab12cd34');
    });

    it('renders the start date as a time ago', () => {
      expect(findTable().findComponent(TimeAgo).props('time')).toBe('2026-09-11T10:00:00.000Z');
    });

    it('renders a status badge per export', () => {
      expect(findStatusBadges()).toHaveLength(2);
      expect(findStatusBadges().at(0).props()).toMatchObject({
        status: 'finished',
        hasFailures: false,
      });
    });
  });

  describe('when an export has no bucket or export prefix', () => {
    beforeEach(async () => {
      mock.onGet(API_URL).reply(HTTP_STATUS_OK, [...mockOfflineExports, mockPurgedExport]);
      createComponent({ mountFn: mountExtended });
      await waitForPromises();
    });

    it('does not render a row for it', () => {
      expect(findTable().findAll('tbody tr')).toHaveLength(2);
      expect(findTable().text()).not.toContain('None');
    });
  });

  describe('when every export has no bucket or export prefix', () => {
    beforeEach(async () => {
      mock.onGet(API_URL).reply(HTTP_STATUS_OK, [mockPurgedExport]);
      createComponent({ mountFn: mountExtended });
      await waitForPromises();
    });

    it('renders the empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('does not render the table', () => {
      expect(findTable().exists()).toBe(false);
    });
  });

  describe('when the request fails', () => {
    beforeEach(async () => {
      mock.onGet(API_URL).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      createComponent();
      await waitForPromises();
    });

    it('renders an alert with a generic message', () => {
      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Something went wrong while fetching offline export history.',
          captureError: true,
        }),
      );
    });

    it('stops loading', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders the empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });
  });
});
