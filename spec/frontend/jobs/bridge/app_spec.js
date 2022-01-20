import { nextTick } from 'vue';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { GlLoadingIcon } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import getPipelineQuery from '~/jobs/bridge/graphql/queries/pipeline.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import BridgeApp from '~/jobs/bridge/app.vue';
import BridgeEmptyState from '~/jobs/bridge/components/empty_state.vue';
import BridgeSidebar from '~/jobs/bridge/components/sidebar.vue';
import CiHeader from '~/vue_shared/components/header_ci_component.vue';
import {
  MOCK_BUILD_ID,
  MOCK_PIPELINE_IID,
  MOCK_PROJECT_FULL_PATH,
  mockPipelineQueryResponse,
} from './mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Bridge Show Page', () => {
  let wrapper;
  let mockApollo;
  let mockPipelineQuery;

  const createComponent = (options) => {
    wrapper = shallowMount(BridgeApp, {
      provide: {
        buildId: MOCK_BUILD_ID,
        projectFullPath: MOCK_PROJECT_FULL_PATH,
        pipelineIid: MOCK_PIPELINE_IID,
      },
      mocks: {
        $apollo: {
          queries: {
            pipeline: {
              loading: true,
            },
          },
        },
      },
      ...options,
    });
  };

  const createComponentWithApollo = () => {
    const handlers = [[getPipelineQuery, mockPipelineQuery]];
    mockApollo = createMockApollo(handlers);

    createComponent({
      localVue,
      apolloProvider: mockApollo,
      mocks: {},
    });
  };

  const findCiHeader = () => wrapper.findComponent(CiHeader);
  const findEmptyState = () => wrapper.findComponent(BridgeEmptyState);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findSidebar = () => wrapper.findComponent(BridgeSidebar);

  beforeEach(() => {
    mockPipelineQuery = jest.fn();
  });

  afterEach(() => {
    mockPipelineQuery.mockReset();
    wrapper.destroy();
  });

  describe('while pipeline query is loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('after pipeline query is loaded', () => {
    beforeEach(() => {
      mockPipelineQuery.mockResolvedValue(mockPipelineQueryResponse);
      createComponentWithApollo();
      waitForPromises();
    });

    it('query is called with correct variables', async () => {
      expect(mockPipelineQuery).toHaveBeenCalledTimes(1);
      expect(mockPipelineQuery).toHaveBeenCalledWith({
        fullPath: MOCK_PROJECT_FULL_PATH,
        iid: MOCK_PIPELINE_IID,
      });
    });

    it('renders CI header state', () => {
      expect(findCiHeader().exists()).toBe(true);
    });

    it('renders empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('renders sidebar', () => {
      expect(findSidebar().exists()).toBe(true);
    });
  });

  describe('sidebar expansion', () => {
    beforeEach(() => {
      mockPipelineQuery.mockResolvedValue(mockPipelineQueryResponse);
      createComponentWithApollo();
      waitForPromises();
    });

    describe('on resize', () => {
      it.each`
        breakpoint | isSidebarExpanded
        ${'xs'}    | ${false}
        ${'sm'}    | ${false}
        ${'md'}    | ${true}
        ${'lg'}    | ${true}
        ${'xl'}    | ${true}
      `(
        'sets isSidebarExpanded to `$isSidebarExpanded` when the breakpoint is "$breakpoint"',
        async ({ breakpoint, isSidebarExpanded }) => {
          jest.spyOn(GlBreakpointInstance, 'getBreakpointSize').mockReturnValue(breakpoint);

          window.dispatchEvent(new Event('resize'));
          await nextTick();

          expect(findSidebar().exists()).toBe(isSidebarExpanded);
        },
      );
    });

    it('toggles expansion on button click', async () => {
      expect(findSidebar().exists()).toBe(true);

      wrapper.vm.toggleSidebar();
      await nextTick();

      expect(findSidebar().exists()).toBe(false);
    });
  });
});
