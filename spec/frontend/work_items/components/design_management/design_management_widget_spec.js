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

describe('DesignWidget', () => {
  let wrapper;

  const oneDesignQueryHandler = jest.fn().mockResolvedValue(designCollectionResponse());
  const twoDesignsQueryHandler = jest
    .fn()
    .mockResolvedValue(designCollectionResponse([mockDesign, mockDesign2]));

  const findWidgetWrapper = () => wrapper.findComponent(WidgetWrapper);
  const findAllDesignItems = () => wrapper.findAllComponents(DesignItem);

  function createComponent({ designCollectionQueryHandler = oneDesignQueryHandler } = {}) {
    wrapper = shallowMountExtended(DesignWidget, {
      apolloProvider: createMockApollo([
        [getWorkItemDesignListQuery, designCollectionQueryHandler],
      ]),
      propsData: {
        workItemId: 'gid://gitlab/WorkItem/1',
      },
      provide: {
        fullPath: 'gitlab-org/gitlab-shell',
      },
    });
  }

  describe('when work item has designs', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('called design collection query', () => {
      expect(oneDesignQueryHandler).toHaveBeenCalled();
    });

    it('renders widget wrapper', () => {
      expect(findWidgetWrapper().exists()).toBe(true);
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
