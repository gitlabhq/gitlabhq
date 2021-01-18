import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import EnvironmentsFolderViewComponent from '~/environments/folder/environments_folder_view.vue';
import axios from '~/lib/utils/axios_utils';
import { environmentsList } from './mock_data';

describe('Environments Folder View', () => {
  let mock;
  let wrapper;

  const mockData = {
    endpoint: 'environments.json',
    folderName: 'review',
    canReadEnvironment: true,
    cssContainerClass: 'container',
    userCalloutsPath: '/callouts',
    lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
    helpCanaryDeploymentsPath: 'help/canary-deployments',
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
  });

  describe('successful request', () => {
    beforeEach(() => {
      mock.onGet(mockData.endpoint).reply(
        200,
        {
          environments: environmentsList,
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

      wrapper = mount(EnvironmentsFolderViewComponent, { propsData: mockData });
      return axios.waitForAll();
    });

    describe('deploy boards', () => {
      it('should render arrow to open deploy boards', () => {
        expect(wrapper.find('.folder-icon[data-testid="chevron-right-icon"]').exists()).toBe(true);
      });
    });
  });
});
