import { GlLoadingIcon, GlModal, GlPagination } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { mount } from '@vue/test-utils';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import SecureFilesList from '~/ci_secure_files/components/secure_files_list.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';

import { secureFiles } from '../mock_data';

const dummyApiVersion = 'v3000';
const dummyProjectId = 1;
const fileSizeLimit = 5;
const dummyUrlRoot = '/gitlab';
const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${dummyProjectId}/secure_files`;

describe('SecureFilesList', () => {
  let wrapper;
  let mock;
  let trackingSpy;

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
    window.gon = {
      api_version: dummyApiVersion,
      relative_url_root: dummyUrlRoot,
    };
  });

  afterEach(() => {
    mock.restore();
    unmockTracking();
  });

  const createWrapper = (admin = true, props = {}) => {
    wrapper = mount(SecureFilesList, {
      provide: {
        projectId: dummyProjectId,
        admin,
        fileSizeLimit,
      },
      ...props,
    });
  };

  const findRows = () => wrapper.findAll('tbody tr');
  const findRowAt = (i) => findRows().at(i);
  const findCell = (i, col) => findRowAt(i).findAll('td').at(col);
  const findHeaderAt = (i) => wrapper.findAll('thead th').at(i);
  const findPagination = () => wrapper.findComponent(GlPagination);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findUploadButton = () => wrapper.findAll('span.gl-button-text');
  const findDeleteModal = () => wrapper.findComponent(GlModal);
  const findUploadInput = () => wrapper.findAll('input[type="file"]').at(0);
  const findDeleteButton = () => wrapper.findAll('[data-testid="delete-button"]');

  describe('when secure files exist in a project', () => {
    beforeEach(async () => {
      mock = new MockAdapter(axios);
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, secureFiles);

      createWrapper();
      await waitForPromises();
    });

    it('displays a table with expected headers', () => {
      const headers = ['File name', 'Uploaded date'];
      headers.forEach((header, i) => {
        expect(findHeaderAt(i).text()).toBe(header);
      });
    });

    it('displays a table with rows', () => {
      expect(findRows()).toHaveLength(secureFiles.length);

      const [secureFile] = secureFiles;

      expect(findCell(0, 0).text()).toBe(secureFile.name);
      expect(findCell(0, 1).findComponent(TimeAgoTooltip).props('time')).toBe(
        secureFile.created_at,
      );
    });

    describe('event tracking', () => {
      it('sends tracking information on list load', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'render_secure_files_list', {});
      });

      it('sends tracking information on file upload', async () => {
        Api.uploadProjectSecureFile = jest.fn().mockResolvedValue();
        Object.defineProperty(findUploadInput().element, 'files', { value: [{}] });
        findUploadInput().trigger('change');

        await waitForPromises();

        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'upload_secure_file', {});
      });

      it('sends tracking information on file deletion', async () => {
        Api.deleteProjectSecureFile = jest.fn().mockResolvedValue();
        findDeleteModal().vm.$emit('ok');
        await waitForPromises();

        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'delete_secure_file', {});
      });
    });
  });

  describe('when no secure files exist in a project', () => {
    beforeEach(async () => {
      mock = new MockAdapter(axios);
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, []);

      createWrapper();
      await waitForPromises();
    });

    it('displays a table with expected headers', () => {
      const headers = ['File name', 'Uploaded date'];
      headers.forEach((header, i) => {
        expect(findHeaderAt(i).text()).toBe(header);
      });
    });

    it('displays a table with a no records message', () => {
      expect(findCell(0, 0).text()).toBe('There are no secure files yet.');
    });
  });

  describe('loading state', () => {
    it('displays the loading icon and hides pagination while waiting for the backend request', () => {
      mock = new MockAdapter(axios);
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, secureFiles);
      createWrapper();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findPagination().exists()).toBe(false);
    });

    it('does not display the loading icon and shows pagination after the backend request has completed', async () => {
      mock = new MockAdapter(axios);
      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, secureFiles);

      createWrapper();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findPagination().exists()).toBe(true);
    });
  });

  describe('admin permissions', () => {
    describe('with admin permissions', () => {
      beforeEach(async () => {
        mock = new MockAdapter(axios);
        mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, secureFiles);

        createWrapper();
        await waitForPromises();
      });

      it('displays the upload button', () => {
        expect(findUploadButton().exists()).toBe(true);
      });

      it('displays a delete button', () => {
        expect(findDeleteButton().exists()).toBe(true);
      });
    });

    describe('without admin permissions', () => {
      beforeEach(async () => {
        mock = new MockAdapter(axios);
        mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, secureFiles);

        createWrapper(false);
        await waitForPromises();
      });

      it('does not display the upload button', () => {
        expect(findUploadButton().exists()).toBe(false);
      });

      it('does not display a delete button', () => {
        expect(findDeleteButton().exists()).toBe(false);
      });
    });
  });
});
