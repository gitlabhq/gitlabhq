import { GlTabs } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import Container from '~/environments/components/container.vue';
import DeployBoard from '~/environments/components/deploy_board.vue';
import EmptyState from '~/environments/components/empty_state.vue';
import EnableReviewAppModal from '~/environments/components/enable_review_app_modal.vue';
import EnvironmentsApp from '~/environments/components/environments_app.vue';
import axios from '~/lib/utils/axios_utils';
import * as urlUtils from '~/lib/utils/url_utility';
import { environment, folder } from './mock_data';

describe('Environment', () => {
  let mock;
  let wrapper;

  const mockData = {
    endpoint: 'environments.json',
    canCreateEnvironment: true,
    canReadEnvironment: true,
    newEnvironmentPath: 'environments/new',
    helpPagePath: 'help',
    userCalloutsPath: '/callouts',
    lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
    helpCanaryDeploymentsPath: 'help/canary-deployments',
  };

  const mockRequest = (response, body) => {
    mock.onGet(mockData.endpoint).reply(response, body, {
      'X-nExt-pAge': '2',
      'x-page': '1',
      'X-Per-Page': '1',
      'X-Prev-Page': '',
      'X-TOTAL': '37',
      'X-Total-Pages': '2',
    });
  };

  const createWrapper = (shallow = false, props = {}) => {
    const fn = shallow ? shallowMount : mount;
    wrapper = extendedWrapper(fn(EnvironmentsApp, { propsData: { ...mockData, ...props } }));
    return axios.waitForAll();
  };

  const findEnableReviewAppButton = () => wrapper.findByTestId('enable-review-app');
  const findEnableReviewAppModal = () => wrapper.findAll(EnableReviewAppModal);
  const findNewEnvironmentButton = () => wrapper.findByTestId('new-environment');
  const findEnvironmentsTabAvailable = () => wrapper.find('.js-environments-tab-available > a');
  const findEnvironmentsTabStopped = () => wrapper.find('.js-environments-tab-stopped > a');

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('successful request', () => {
    describe('without environments', () => {
      beforeEach(() => {
        mockRequest(200, { environments: [] });
        return createWrapper();
      });

      it('should render the empty state', () => {
        expect(wrapper.find(EmptyState).exists()).toBe(true);
      });
    });

    describe('with paginated environments', () => {
      const environmentList = [environment];

      beforeEach(() => {
        mockRequest(200, {
          environments: environmentList,
          stopped_count: 1,
          available_count: 0,
        });
        return createWrapper();
      });

      it('should render a container table with environments', () => {
        const containerTable = wrapper.find(Container);

        expect(containerTable.exists()).toBe(true);
        expect(containerTable.props('environments').length).toEqual(environmentList.length);
        expect(containerTable.find('.environment-name').text()).toEqual(environmentList[0].name);
      });

      describe('pagination', () => {
        it('should render pagination', () => {
          expect(wrapper.findAll('.gl-pagination li').length).toEqual(9);
        });

        it('should make an API request when page is clicked', () => {
          jest.spyOn(wrapper.vm, 'updateContent').mockImplementation(() => {});

          wrapper.find('.gl-pagination li:nth-child(3) .page-link').trigger('click');
          expect(wrapper.vm.updateContent).toHaveBeenCalledWith({
            scope: 'available',
            page: '2',
            nested: true,
          });
        });

        it('should make an API request when using tabs', () => {
          jest.spyOn(wrapper.vm, 'updateContent').mockImplementation(() => {});
          findEnvironmentsTabStopped().trigger('click');
          expect(wrapper.vm.updateContent).toHaveBeenCalledWith({
            scope: 'stopped',
            page: '1',
            nested: true,
          });
        });

        it('should not make the same API request when clicking on the current scope tab', () => {
          // component starts at available
          jest.spyOn(wrapper.vm, 'updateContent').mockImplementation(() => {});
          findEnvironmentsTabAvailable().trigger('click');
          expect(wrapper.vm.updateContent).toHaveBeenCalledTimes(0);
        });
      });

      describe('deploy boards', () => {
        beforeEach(() => {
          const deployEnvironment = {
            ...environment,
            rollout_status: {
              status: 'found',
            },
          };

          mockRequest(200, {
            environments: [deployEnvironment],
            stopped_count: 1,
            available_count: 0,
          });

          return createWrapper();
        });

        it('should render deploy boards', () => {
          expect(wrapper.find(DeployBoard).exists()).toBe(true);
        });

        it('should render arrow to open deploy boards', () => {
          expect(
            wrapper.find('.deploy-board-icon [data-testid="chevron-down-icon"]').exists(),
          ).toBe(true);
        });
      });
    });
  });

  describe('unsuccessful request', () => {
    beforeEach(() => {
      mockRequest(500, {});
      return createWrapper();
    });

    it('should render empty state', () => {
      expect(wrapper.find(EmptyState).exists()).toBe(true);
    });
  });

  describe('expandable folders', () => {
    beforeEach(() => {
      mockRequest(200, {
        environments: [folder],
        stopped_count: 1,
        available_count: 0,
      });

      mock.onGet(environment.folder_path).reply(200, { environments: [environment] });

      return createWrapper().then(() => {
        // open folder
        wrapper.find('.folder-name').trigger('click');
        return axios.waitForAll();
      });
    });

    it('should open a closed folder', () => {
      expect(wrapper.find('.folder-icon[data-testid="chevron-right-icon"]').exists()).toBe(false);
    });

    it('should close an opened folder', () => {
      expect(wrapper.find('.folder-icon[data-testid="chevron-down-icon"]').exists()).toBe(true);

      // close folder
      wrapper.find('.folder-name').trigger('click');
      wrapper.vm.$nextTick(() => {
        expect(wrapper.find('.folder-icon[data-testid="chevron-down-icon"]').exists()).toBe(false);
      });
    });

    it('should show children environments', () => {
      expect(wrapper.findAll('.js-child-row').length).toEqual(1);
    });

    it('should show a button to show all environments', () => {
      expect(wrapper.find('.text-center > a.btn').text()).toContain('Show all');
    });
  });

  describe('environment button', () => {
    describe('when user can create environment', () => {
      beforeEach(() => {
        mockRequest(200, { environments: [] });
        return createWrapper(true);
      });

      it('should render', () => {
        expect(findNewEnvironmentButton().exists()).toBe(true);
      });
    });

    describe('when user can not create environment', () => {
      beforeEach(() => {
        mockRequest(200, { environments: [] });
        return createWrapper(true, { ...mockData, canCreateEnvironment: false });
      });

      it('should not render', () => {
        expect(findNewEnvironmentButton().exists()).toBe(false);
      });
    });
  });

  describe('review app modal', () => {
    describe('when it is not possible to enable a review app', () => {
      beforeEach(() => {
        mockRequest(200, { environments: [] });
        return createWrapper(true);
      });

      it('should not render the enable review app button', () => {
        expect(findEnableReviewAppButton().exists()).toBe(false);
      });

      it('should not render a review app modal', () => {
        const modal = findEnableReviewAppModal();
        expect(modal).toHaveLength(0);
        expect(modal.exists()).toBe(false);
      });
    });

    describe('when it is possible to enable a review app', () => {
      beforeEach(() => {
        mockRequest(200, { environments: [], review_app: { can_setup_review_app: true } });
        return createWrapper(true);
      });

      it('should render the enable review app button', () => {
        expect(findEnableReviewAppButton().exists()).toBe(true);
        expect(findEnableReviewAppButton().text()).toContain('Enable review app');
      });

      it('should render only one review app modal', () => {
        const modal = findEnableReviewAppModal();
        expect(modal).toHaveLength(1);
        expect(modal.at(0).exists()).toBe(true);
      });
    });
  });

  describe('tabs', () => {
    beforeEach(() => {
      mockRequest(200, { environments: [] });
      jest
        .spyOn(urlUtils, 'getParameterByName')
        .mockImplementation((param) => (param === 'scope' ? 'stopped' : null));
      return createWrapper(true);
    });

    it('selects the tab for the parameter', () => {
      expect(wrapper.findComponent(GlTabs).attributes('value')).toBe('1');
    });
  });
});
