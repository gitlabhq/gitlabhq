import { GlLoadingIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { mount } from '@vue/test-utils';
import axios from '~/lib/utils/axios_utils';
import SecureFilesList from '~/ci_secure_files/components/secure_files_list.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import waitForPromises from 'helpers/wait_for_promises';

import { secureFiles } from '../mock_data';

const dummyApiVersion = 'v3000';
const dummyProjectId = 1;
const dummyUrlRoot = '/gitlab';
const dummyGon = {
  api_version: dummyApiVersion,
  relative_url_root: dummyUrlRoot,
};
let originalGon;
const expectedUrl = `${dummyUrlRoot}/api/${dummyApiVersion}/projects/${dummyProjectId}/secure_files`;

describe('SecureFilesList', () => {
  let wrapper;
  let mock;

  beforeEach(() => {
    originalGon = window.gon;
    window.gon = { ...dummyGon };
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
    window.gon = originalGon;
  });

  const createWrapper = (props = {}) => {
    wrapper = mount(SecureFilesList, {
      provide: { projectId: dummyProjectId },
      ...props,
    });
  };

  const findRows = () => wrapper.findAll('tbody tr');
  const findRowAt = (i) => findRows().at(i);
  const findCell = (i, col) => findRowAt(i).findAll('td').at(col);
  const findHeaderAt = (i) => wrapper.findAll('thead th').at(i);
  const findPagination = () => wrapper.findAll('ul.pagination');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  describe('when secure files exist in a project', () => {
    beforeEach(async () => {
      mock = new MockAdapter(axios);
      mock.onGet(expectedUrl).reply(200, secureFiles);

      createWrapper();
      await waitForPromises();
    });

    it('displays a table with expected headers', () => {
      const headers = ['Filename', 'Permissions', 'Uploaded'];
      headers.forEach((header, i) => {
        expect(findHeaderAt(i).text()).toBe(header);
      });
    });

    it('displays a table with rows', () => {
      expect(findRows()).toHaveLength(secureFiles.length);

      const [secureFile] = secureFiles;

      expect(findCell(0, 0).text()).toBe(secureFile.name);
      expect(findCell(0, 1).text()).toBe(secureFile.permissions);
      expect(findCell(0, 2).find(TimeAgoTooltip).props('time')).toBe(secureFile.created_at);
    });
  });

  describe('when no secure files exist in a project', () => {
    beforeEach(async () => {
      mock = new MockAdapter(axios);
      mock.onGet(expectedUrl).reply(200, []);

      createWrapper();
      await waitForPromises();
    });

    it('displays a table with expected headers', () => {
      const headers = ['Filename', 'Permissions', 'Uploaded'];
      headers.forEach((header, i) => {
        expect(findHeaderAt(i).text()).toBe(header);
      });
    });

    it('displays a table with a no records message', () => {
      expect(findCell(0, 0).text()).toBe('There are no records to show');
    });
  });

  describe('pagination', () => {
    it('displays the pagination component with there are more than 20 items', async () => {
      mock = new MockAdapter(axios);
      mock.onGet(expectedUrl).reply(200, secureFiles, { 'x-total': 30 });

      createWrapper();
      await waitForPromises();

      expect(findPagination().exists()).toBe(true);
    });

    it('does not display the pagination component with there are 20 items', async () => {
      mock = new MockAdapter(axios);
      mock.onGet(expectedUrl).reply(200, secureFiles, { 'x-total': 20 });

      createWrapper();
      await waitForPromises();

      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('loading state', () => {
    it('displays the loading icon while waiting for the backend request', () => {
      mock = new MockAdapter(axios);
      mock.onGet(expectedUrl).reply(200, secureFiles);
      createWrapper();

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not display the loading icon after the backend request has completed', async () => {
      mock = new MockAdapter(axios);
      mock.onGet(expectedUrl).reply(200, secureFiles);

      createWrapper();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });
});
