import { mount } from '@vue/test-utils';
import CanaryUpdateModal from '~/environments/components/canary_update_modal.vue';
import DeployBoard from '~/environments/components/deploy_board.vue';
import EnvironmentTable from '~/environments/components/environments_table.vue';
import eventHub from '~/environments/event_hub';
import { folder, deployBoardMockData } from './mock_data';

const eeOnlyProps = {
  userCalloutsPath: '/callouts',
  lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
  helpCanaryDeploymentsPath: 'help/canary-deployments',
};

describe('Environment table', () => {
  let wrapper;

  const factory = (options = {}) => {
    // This destroys any wrappers created before a nested call to factory reassigns it
    if (wrapper && wrapper.destroy) {
      wrapper.destroy();
    }
    wrapper = mount(EnvironmentTable, {
      ...options,
    });
  };

  beforeEach(() => {
    factory({
      propsData: {
        environments: [folder],
        canReadEnvironment: true,
        ...eeOnlyProps,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Should render a table', async () => {
    const mockItem = {
      name: 'review',
      folderName: 'review',
      size: 3,
      isFolder: true,
      environment_path: 'url',
    };

    await factory({
      propsData: {
        environments: [mockItem],
        canReadEnvironment: true,
        userCalloutsPath: '/callouts',
        lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
        helpCanaryDeploymentsPath: 'help/canary-deployments',
      },
    });

    expect(wrapper.classes()).toContain('ci-table');
  });

  it('should render deploy board container when data is provided', async () => {
    const mockItem = {
      name: 'review',
      size: 1,
      environment_path: 'url',
      logs_path: 'url',
      id: 1,
      hasDeployBoard: true,
      deployBoardData: deployBoardMockData,
      isDeployBoardVisible: true,
      isLoadingDeployBoard: false,
      isEmptyDeployBoard: false,
    };

    await factory({
      propsData: {
        environments: [mockItem],
        canCreateDeployment: false,
        canReadEnvironment: true,
        userCalloutsPath: '/callouts',
        lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
        helpCanaryDeploymentsPath: 'help/canary-deployments',
      },
    });

    expect(wrapper.find('.js-deploy-board-row').exists()).toBe(true);
    expect(wrapper.find('.deploy-board-icon').exists()).toBe(true);
  });

  it('should render deploy board container when data is provided for children', async () => {
    const mockItem = {
      name: 'review',
      size: 1,
      environment_path: 'url',
      logs_path: 'url',
      id: 1,
      isFolder: true,
      isOpen: true,
      children: [
        {
          name: 'review/test',
          hasDeployBoard: true,
          deployBoardData: deployBoardMockData,
          isDeployBoardVisible: true,
          isLoadingDeployBoard: false,
          isEmptyDeployBoard: false,
        },
      ],
    };

    await factory({
      propsData: {
        environments: [mockItem],
        canCreateDeployment: false,
        canReadEnvironment: true,
        userCalloutsPath: '/callouts',
        lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
        helpCanaryDeploymentsPath: 'help/canary-deployments',
      },
    });

    expect(wrapper.find('.js-deploy-board-row').exists()).toBe(true);
    expect(wrapper.find('.deploy-board-icon').exists()).toBe(true);
  });

  it('should toggle deploy board visibility when arrow is clicked', (done) => {
    const mockItem = {
      name: 'review',
      size: 1,
      environment_path: 'url',
      id: 1,
      hasDeployBoard: true,
      deployBoardData: {
        instances: [{ status: 'ready', tooltip: 'foo' }],
        abort_url: 'url',
        rollback_url: 'url',
        completion: 100,
        is_completed: true,
        canary_ingress: { canary_weight: 60 },
      },
      isDeployBoardVisible: false,
    };

    eventHub.$on('toggleDeployBoard', (env) => {
      expect(env.id).toEqual(mockItem.id);
      done();
    });

    factory({
      propsData: {
        environments: [mockItem],
        canReadEnvironment: true,
        userCalloutsPath: '/callouts',
        lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
        helpCanaryDeploymentsPath: 'help/canary-deployments',
      },
    });

    wrapper.find('.deploy-board-icon').trigger('click');
  });

  it('should set the environment to change and weight when a change canary weight event is recevied', async () => {
    const mockItem = {
      name: 'review',
      size: 1,
      environment_path: 'url',
      logs_path: 'url',
      id: 1,
      hasDeployBoard: true,
      deployBoardData: deployBoardMockData,
      isDeployBoardVisible: true,
      isLoadingDeployBoard: false,
      isEmptyDeployBoard: false,
    };

    await factory({
      propsData: {
        environments: [mockItem],
        canCreateDeployment: false,
        canReadEnvironment: true,
        userCalloutsPath: '/callouts',
        lockPromotionSvgPath: '/assets/illustrations/lock-promotion.svg',
        helpCanaryDeploymentsPath: 'help/canary-deployments',
      },
    });

    wrapper.find(DeployBoard).vm.$emit('changeCanaryWeight', 40);
    await wrapper.vm.$nextTick();

    expect(wrapper.find(CanaryUpdateModal).props()).toMatchObject({
      weight: 40,
      environment: mockItem,
    });
  });

  describe('sortEnvironments', () => {
    it('should sort environments by last updated', () => {
      const mockItems = [
        {
          name: 'old',
          size: 3,
          isFolder: false,
          last_deployment: {
            created_at: new Date(2019, 0, 5).toISOString(),
          },
        },
        {
          name: 'new',
          size: 3,
          isFolder: false,
          last_deployment: {
            created_at: new Date(2019, 1, 5).toISOString(),
          },
        },
        {
          name: 'older',
          size: 3,
          isFolder: false,
          last_deployment: {
            created_at: new Date(2018, 0, 5).toISOString(),
          },
        },
        {
          name: 'an environment with no deployment',
        },
      ];

      factory({
        propsData: {
          environments: mockItems,
          canReadEnvironment: true,
          ...eeOnlyProps,
        },
      });

      const [old, newer, older, noDeploy] = mockItems;

      expect(wrapper.vm.sortEnvironments(mockItems)).toEqual([newer, old, older, noDeploy]);
    });

    it('should push environments with no deployments to the bottom', () => {
      const mockItems = [
        {
          name: 'production',
          size: 1,
          id: 2,
          state: 'available',
          external_url: 'https://google.com/production',
          environment_type: null,
          last_deployment: null,
          has_stop_action: false,
          environment_path: '/Commit451/lab-coat/environments/2',
          stop_path: '/Commit451/lab-coat/environments/2/stop',
          folder_path: '/Commit451/lab-coat/environments/folders/production',
          created_at: '2019-01-17T16:26:10.064Z',
          updated_at: '2019-01-17T16:27:37.717Z',
          can_stop: true,
        },
        {
          name: 'review/225addcibuildstatus',
          size: 2,
          isFolder: true,
          isLoadingFolderContent: false,
          folderName: 'review',
          isOpen: false,
          children: [],
          id: 12,
          state: 'available',
          external_url: 'https://google.com/review/225addcibuildstatus',
          environment_type: 'review',
          last_deployment: null,
          has_stop_action: false,
          environment_path: '/Commit451/lab-coat/environments/12',
          stop_path: '/Commit451/lab-coat/environments/12/stop',
          folder_path: '/Commit451/lab-coat/environments/folders/review',
          created_at: '2019-01-17T16:27:37.877Z',
          updated_at: '2019-01-17T16:27:37.883Z',
          can_stop: true,
        },
        {
          name: 'staging',
          size: 1,
          id: 1,
          state: 'available',
          external_url: 'https://google.com/staging',
          environment_type: null,
          last_deployment: {
            created_at: '2019-01-17T16:26:15.125Z',
            scheduled_actions: [],
          },
        },
      ];

      factory({
        propsData: {
          environments: mockItems,
          canReadEnvironment: true,
          ...eeOnlyProps,
        },
      });

      const [prod, review, staging] = mockItems;

      expect(wrapper.vm.sortEnvironments(mockItems)).toEqual([review, staging, prod]);
    });

    it('should sort environments by folder first', () => {
      const mockItems = [
        {
          name: 'old',
          size: 3,
          isFolder: false,
          last_deployment: {
            created_at: new Date(2019, 0, 5).toISOString(),
          },
        },
        {
          name: 'new',
          size: 3,
          isFolder: false,
          last_deployment: {
            created_at: new Date(2019, 1, 5).toISOString(),
          },
        },
        {
          name: 'older',
          size: 3,
          isFolder: true,
          children: [],
        },
      ];

      factory({
        propsData: {
          environments: mockItems,
          canReadEnvironment: true,
          ...eeOnlyProps,
        },
      });

      const [old, newer, older] = mockItems;

      expect(wrapper.vm.sortEnvironments(mockItems)).toEqual([older, newer, old]);
    });

    it('should break ties by name', () => {
      const mockItems = [
        {
          name: 'old',
          isFolder: false,
        },
        {
          name: 'new',
          isFolder: false,
        },
        {
          folderName: 'older',
          isFolder: true,
        },
      ];

      factory({
        propsData: {
          environments: mockItems,
          canReadEnvironment: true,
          ...eeOnlyProps,
        },
      });

      const [old, newer, older] = mockItems;

      expect(wrapper.vm.sortEnvironments(mockItems)).toEqual([older, newer, old]);
    });
  });

  describe('sortedEnvironments', () => {
    it('it should sort children as well', () => {
      const mockItems = [
        {
          name: 'production',
          last_deployment: null,
        },
        {
          name: 'review/225addcibuildstatus',
          isFolder: true,
          folderName: 'review',
          isOpen: true,
          children: [
            {
              name: 'review/225addcibuildstatus',
              last_deployment: {
                created_at: '2019-01-17T16:26:15.125Z',
              },
            },
            {
              name: 'review/main',
              last_deployment: {
                created_at: '2019-02-17T16:26:15.125Z',
              },
            },
          ],
        },
        {
          name: 'staging',
          last_deployment: {
            created_at: '2019-01-17T16:26:15.125Z',
          },
        },
      ];
      const [production, review, staging] = mockItems;
      const [addcibuildstatus, main] = mockItems[1].children;

      factory({
        propsData: {
          environments: mockItems,
          canReadEnvironment: true,
          ...eeOnlyProps,
        },
      });

      expect(wrapper.vm.sortedEnvironments.map((env) => env.name)).toEqual([
        review.name,
        staging.name,
        production.name,
      ]);

      expect(wrapper.vm.sortedEnvironments[0].children).toEqual([main, addcibuildstatus]);
    });
  });
});
