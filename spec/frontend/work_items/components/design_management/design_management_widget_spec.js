import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import CrudComponent from '~/vue_shared/components/crud_component.vue';
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

  const findWidgetWrapper = () => wrapper.findComponent(CrudComponent);
  const findAllDesignItems = () => wrapper.findAllComponents(DesignItem);
  const findAlert = () => wrapper.findComponent(GlAlert);

  function createComponent({
    designCollectionQueryHandler = oneDesignQueryHandler,
    routeArg = MOCK_ROUTE,
    uploadError = null,
  } = {}) {
    wrapper = shallowMountExtended(DesignWidget, {
      apolloProvider: createMockApollo([
        [getWorkItemDesignListQuery, designCollectionQueryHandler],
      ]),
      propsData: {
        workItemId,
        uploadError,
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

  it('dismisses error passed as prop', async () => {
    createComponent({ uploadError: 'Error uploading a new design. Please try again.' });
    await waitForPromises();

    expect(findAlert().exists()).toBe(true);
    findAlert().vm.$emit('dismiss');

    expect(wrapper.emitted('dismissError')).toHaveLength(1);
  });
});
