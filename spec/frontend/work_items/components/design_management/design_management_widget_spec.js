import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import WidgetWrapper from '~/work_items/components/widget_wrapper.vue';
import getWorkItemDesignListQuery from '~/work_items/components/design_management/graphql/design_collection.query.graphql';
import DesignItem from '~/work_items/components/design_management/design_item.vue';
import DesignWidget from '~/work_items/components/design_management/design_management_widget.vue';

import { designCollectionResponse, mockDesign, mockDesign2 } from './mock_data';

Vue.use(VueApollo);

const PREVIOUS_VERSION_ID = 2;

const designRouteFactory = (versionId) => ({
  path: `?version=${versionId}`,
  query: {
    version: `${versionId}`,
  },
});

const MOCK_ROUTE = {
  path: '/',
  query: {},
};

describe('DesignWidget', () => {
  let wrapper;
  const workItemId = 'gid://gitlab/WorkItem/1';

  const oneDesignQueryHandler = jest.fn().mockResolvedValue(designCollectionResponse());
  const twoDesignsQueryHandler = jest
    .fn()
    .mockResolvedValue(designCollectionResponse([mockDesign, mockDesign2]));

  const findWidgetWrapper = () => wrapper.findComponent(WidgetWrapper);
  const findAllDesignItems = () => wrapper.findAllComponents(DesignItem);

  function createComponent({
    designCollectionQueryHandler = oneDesignQueryHandler,
    routeArg = MOCK_ROUTE,
  } = {}) {
    wrapper = shallowMountExtended(DesignWidget, {
      apolloProvider: createMockApollo([
        [getWorkItemDesignListQuery, designCollectionQueryHandler],
      ]),
      propsData: {
        workItemId,
      },
      mocks: {
        $route: routeArg,
      },
      provide: {
        fullPath: 'gitlab-org/gitlab-shell',
      },
      stubs: {
        RouterView: true,
      },
    });
  }

  describe('when work item has designs', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('calls design collection query without version by default', () => {
      expect(oneDesignQueryHandler).toHaveBeenCalledWith({
        id: workItemId,
        atVersion: null,
      });
    });

    it('renders widget wrapper', () => {
      expect(findWidgetWrapper().exists()).toBe(true);
    });
  });

  it('calls design collection query with version passed in route', async () => {
    createComponent({ routeArg: designRouteFactory(PREVIOUS_VERSION_ID) });

    await waitForPromises();

    expect(oneDesignQueryHandler).toHaveBeenCalledWith({
      id: workItemId,
      atVersion: `gid://gitlab/DesignManagement::Version/${PREVIOUS_VERSION_ID}`,
    });
  });

  it.each`
    length | queryHandler
    ${1}   | ${oneDesignQueryHandler}
    ${2}   | ${twoDesignsQueryHandler}
  `('renders $length designs', async ({ length, queryHandler }) => {
    createComponent({ designCollectionQueryHandler: queryHandler });
    await waitForPromises();

    expect(queryHandler).toHaveBeenCalled();
    expect(findAllDesignItems().length).toBe(length);
  });
});
