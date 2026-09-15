import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlIcon, GlLink } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import WorkItemLinkedResources from '~/work_items/components/work_item_linked_resources.vue';
import workItemLinkedResourcesQuery from '~/work_items/graphql/work_item_linked_resources.query.graphql';
import workItemLinkedResourcesUpdatedSubscription from '~/work_items/graphql/work_item_linked_resources.subscription.graphql';
import { workItemLinkedResourcesResponseFactory } from 'ee_else_ce_jest/work_items/mock_data';

Vue.use(VueApollo);

describe('WorkItemLinkedResources component', () => {
  let wrapper;

  const zoomUrl = 'http://zoom.example.com/j/1234567890';
  const successHandler = jest.fn().mockResolvedValue(workItemLinkedResourcesResponseFactory());
  const subscriptionHandler = jest.fn().mockResolvedValue({ data: { workItemUpdated: null } });

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findLinkedResourceItems = () => wrapper.findAllComponents(GlLink);

  const createComponent = ({ handler = successHandler, provide = {} } = {}) => {
    wrapper = shallowMountExtended(WorkItemLinkedResources, {
      apolloProvider: createMockApollo([
        [workItemLinkedResourcesQuery, handler],
        [workItemLinkedResourcesUpdatedSubscription, subscriptionHandler],
      ]),
      propsData: {
        fullPath: 'group/project',
        workItemIid: '1',
      },
      provide,
    });
  };

  describe('when the work item has linked resources', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders CrudComponent', () => {
      expect(findCrudComponent().props()).toMatchObject({
        anchorId: 'resources',
        count: 1,
        isCollapsible: true,
        persistCollapsedState: true,
        title: 'Resources',
      });
    });

    it('renders correct text and link for resource', () => {
      expect(findLinkedResourceItems()).toHaveLength(1);
      expect(findLinkedResourceItems().at(0).text()).toBe('Zoom link');
      expect(findLinkedResourceItems().at(0).attributes('href')).toBe(zoomUrl);
    });

    it('renders zoom icon for resource', () => {
      expect(findLinkedResourceItems().at(0).findComponent(GlIcon).props('name')).toBe(
        'brand-zoom',
      );
    });

    it('subscribes to work item updates so quick actions are reflected', () => {
      expect(subscriptionHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/WorkItem/1',
        useWorkItemFeatures: false,
      });
    });
  });

  describe('when the work item features field is enabled', () => {
    it('reads the resources from the features field', async () => {
      const featuresHandler = jest
        .fn()
        .mockResolvedValue(workItemLinkedResourcesResponseFactory({ useWorkItemFeatures: true }));
      createComponent({
        handler: featuresHandler,
        provide: { glFeatures: { workItemFeaturesField: true } },
      });
      await waitForPromises();

      expect(featuresHandler).toHaveBeenCalledWith(
        expect.objectContaining({ useWorkItemFeatures: true }),
      );
      expect(findLinkedResourceItems()).toHaveLength(1);
    });
  });

  describe('when the work item has no linked resources', () => {
    beforeEach(async () => {
      createComponent({
        handler: jest
          .fn()
          .mockResolvedValue(workItemLinkedResourcesResponseFactory({ resources: [] })),
      });
      await waitForPromises();
    });

    it('does not render the panel', () => {
      expect(findCrudComponent().exists()).toBe(false);
    });
  });

  describe('when the query fails', () => {
    beforeEach(async () => {
      jest.spyOn(Sentry, 'captureException').mockImplementation();
      createComponent({ handler: jest.fn().mockRejectedValue(new Error('Network error')) });
      await waitForPromises();
    });

    it('reports the failure to Sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
    });

    it('emits the error with error message', () => {
      expect(findCrudComponent().exists()).toBe(false);
      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong when fetching resources. Please try again.'],
      ]);
    });
  });
});
