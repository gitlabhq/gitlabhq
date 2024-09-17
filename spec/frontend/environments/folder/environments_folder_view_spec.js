import { GlPagination } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { removeBreakLine, removeWhitespace } from 'helpers/text_helper';
import EnvironmentTable from '~/environments/components/environments_table.vue';
import ConfirmRollbackModal from '~/environments/components/confirm_rollback_modal.vue';
import EnvironmentsFolderViewComponent from '~/environments/folder/environments_folder_view.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { environmentsList } from '../mock_data';

describe('Environments Folder View', () => {
  let mock;
  let wrapper;

  const mockData = {
    endpoint: 'environments.json',
    folderName: 'review',
    cssContainerClass: 'container',
    userCalloutsPath: '/callouts',
    lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
    helpCanaryDeploymentsPath: 'help/canary-deployments',
  };

  const mockEnvironments = (environmentList) => {
    mock.onGet(mockData.endpoint).reply(
      HTTP_STATUS_OK,
      {
        environments: environmentList,
        stopped_count: 1,
        available_count: 0,
      },
      {
        'X-nExt-pAge': '2',
        'x-page': '1',
        'X-Per-Page': '2',
        'X-Prev-Page': '',
        'X-TOTAL': '20',
        'X-Total-Pages': '10',
      },
    );
  };

  const createWrapper = () => {
    wrapper = mount(EnvironmentsFolderViewComponent, { propsData: mockData });
  };

  const findEnvironmentsTabAvailable = () =>
    wrapper.find('[data-testid="environments-tab-available"]');

  const findEnvironmentsTabStopped = () => wrapper.find('[data-testid="environments-tab-stopped"]');

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('successful request', () => {
    beforeEach(() => {
      mockEnvironments(environmentsList);
      createWrapper();
      return axios.waitForAll();
    });

    it('should render a table with environments', () => {
      const table = wrapper.findComponent(EnvironmentTable);

      expect(table.exists()).toBe(true);
      expect(table.find('.environment-name').text()).toEqual(environmentsList[0].name);
    });

    it('should render available tab with count', () => {
      const tabTable = findEnvironmentsTabAvailable();

      expect(tabTable.text()).toContain('Available');
      expect(tabTable.find('.badge').text()).toContain('0');
    });

    it('should render stopped tab with count', () => {
      const tabTable = findEnvironmentsTabStopped();

      expect(tabTable.text()).toContain('Stopped');
      expect(tabTable.find('.badge').text()).toContain('1');
    });

    it('should render parent folder name', () => {
      expect(
        removeBreakLine(removeWhitespace(wrapper.find('[data-testid="folder-name"]').text())),
      ).toContain('Environments / review');
    });

    it('should render the confirm rollback modal', () => {
      expect(wrapper.findComponent(ConfirmRollbackModal).exists()).toBe(true);
    });

    describe('pagination', () => {
      it('should render pagination', () => {
        expect(wrapper.findComponent(GlPagination).exists()).toBe(true);
      });
    });
  });

  describe('unsuccessful request', () => {
    beforeEach(() => {
      mock.onGet(mockData.endpoint).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, { environments: [] });
      createWrapper();
      return axios.waitForAll();
    });

    it('should not render a table', () => {
      expect(wrapper.findComponent(EnvironmentTable).exists()).toBe(false);
    });

    it('should render available tab with count 0', () => {
      const tabTable = findEnvironmentsTabAvailable();

      expect(tabTable.text()).toContain('Available');
      expect(tabTable.find('.badge').text()).toContain('0');
    });

    it('should render stopped tab with count 0', () => {
      const tabTable = findEnvironmentsTabStopped();

      expect(tabTable.text()).toContain('Stopped');
      expect(tabTable.find('.badge').text()).toContain('0');
    });
  });
});
