import { GlAlert, GlSkeletonLoader, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import WorkItemDescription from '~/work_items/components/work_item_description.vue';
import WorkItemState from '~/work_items/components/work_item_state.vue';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import WorkItemAssignees from '~/work_items/components/work_item_assignees.vue';
import WorkItemLabels from '~/work_items/components/work_item_labels.vue';
import WorkItemWeight from '~/work_items/components/work_item_weight.vue';
import WorkItemInformation from '~/work_items/components/work_item_information.vue';
import { i18n } from '~/work_items/constants';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import workItemTitleSubscription from '~/work_items/graphql/work_item_title.subscription.graphql';
import { temporaryConfig } from '~/work_items/graphql/provider';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import {
  workItemTitleSubscriptionResponse,
  workItemResponseFactory,
  mockParent,
} from '../mock_data';

describe('WorkItemDetail component', () => {
  let wrapper;
  useLocalStorageSpy();

  Vue.use(VueApollo);

  const workItemQueryResponse = workItemResponseFactory();
  const successHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
  const initialSubscriptionHandler = jest.fn().mockResolvedValue(workItemTitleSubscriptionResponse);

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findSkeleton = () => wrapper.findComponent(GlSkeletonLoader);
  const findWorkItemTitle = () => wrapper.findComponent(WorkItemTitle);
  const findWorkItemState = () => wrapper.findComponent(WorkItemState);
  const findWorkItemDescription = () => wrapper.findComponent(WorkItemDescription);
  const findWorkItemAssignees = () => wrapper.findComponent(WorkItemAssignees);
  const findWorkItemLabels = () => wrapper.findComponent(WorkItemLabels);
  const findWorkItemWeight = () => wrapper.findComponent(WorkItemWeight);
  const findParent = () => wrapper.find('[data-testid="work-item-parent"]');
  const findParentButton = () => findParent().findComponent(GlButton);
  const findCloseButton = () => wrapper.find('[data-testid="work-item-close"]');
  const findWorkItemType = () => wrapper.find('[data-testid="work-item-type"]');
  const findWorkItemInformationAlert = () => wrapper.findComponent(WorkItemInformation);
  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);

  const createComponent = ({
    isModal = false,
    workItemId = workItemQueryResponse.data.workItem.id,
    handler = successHandler,
    subscriptionHandler = initialSubscriptionHandler,
    workItemsMvc2Enabled = false,
    includeWidgets = false,
  } = {}) => {
    wrapper = shallowMount(WorkItemDetail, {
      apolloProvider: createMockApollo(
        [
          [workItemQuery, handler],
          [workItemTitleSubscription, subscriptionHandler],
        ],
        {},
        {
          typePolicies: includeWidgets ? temporaryConfig.cacheConfig.typePolicies : {},
        },
      ),
      propsData: { isModal, workItemId },
      provide: {
        glFeatures: {
          workItemsMvc2: workItemsMvc2Enabled,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when there is no `workItemId` prop', () => {
    beforeEach(() => {
      createComponent({ workItemId: null });
    });

    it('skips the work item query', () => {
      expect(successHandler).not.toHaveBeenCalled();
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders skeleton loader', () => {
      expect(findSkeleton().exists()).toBe(true);
      expect(findWorkItemState().exists()).toBe(false);
      expect(findWorkItemTitle().exists()).toBe(false);
    });
  });

  describe('when loaded', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('does not render skeleton', () => {
      expect(findSkeleton().exists()).toBe(false);
      expect(findWorkItemState().exists()).toBe(true);
      expect(findWorkItemTitle().exists()).toBe(true);
    });
  });

  describe('close button', () => {
    describe('when isModal prop is false', () => {
      it('does not render', async () => {
        createComponent({ isModal: false });
        await waitForPromises();

        expect(findCloseButton().exists()).toBe(false);
      });
    });

    describe('when isModal prop is true', () => {
      it('renders', async () => {
        createComponent({ isModal: true });
        await waitForPromises();

        expect(findCloseButton().props('icon')).toBe('close');
        expect(findCloseButton().attributes('aria-label')).toBe('Close');
      });

      it('emits `close` event when clicked', async () => {
        createComponent({ isModal: true });
        await waitForPromises();

        findCloseButton().vm.$emit('click');

        expect(wrapper.emitted('close')).toEqual([[]]);
      });
    });
  });

  describe('description', () => {
    it('does not show description widget if loading description fails', () => {
      createComponent();

      expect(findWorkItemDescription().exists()).toBe(false);
    });

    it('shows description widget if description loads', async () => {
      createComponent();
      await waitForPromises();

      expect(findWorkItemDescription().exists()).toBe(true);
    });
  });

  describe('secondary breadcrumbs', () => {
    it('does not show secondary breadcrumbs by default', () => {
      createComponent();

      expect(findParent().exists()).toBe(false);
    });

    it('does not show secondary breadcrumbs if there is not a parent', async () => {
      createComponent();

      await waitForPromises();

      expect(findParent().exists()).toBe(false);
    });

    it('shows work item type if there is not a parent', async () => {
      createComponent();

      await waitForPromises();
      expect(findWorkItemType().exists()).toBe(true);
    });

    describe('with parent', () => {
      beforeEach(() => {
        const parentResponse = workItemResponseFactory(mockParent);
        createComponent({ handler: jest.fn().mockResolvedValue(parentResponse) });

        return waitForPromises();
      });

      it('shows secondary breadcrumbs if there is a parent', () => {
        expect(findParent().exists()).toBe(true);
      });

      it('does not show work item type', async () => {
        expect(findWorkItemType().exists()).toBe(false);
      });

      it('sets the parent breadcrumb URL', () => {
        expect(findParentButton().attributes().href).toBe('../../issues/5');
      });
    });
  });

  it('shows an error message when the work item query was unsuccessful', async () => {
    const errorHandler = jest.fn().mockRejectedValue('Oops');
    createComponent({ handler: errorHandler });
    await waitForPromises();

    expect(errorHandler).toHaveBeenCalled();
    expect(findAlert().text()).toBe(i18n.fetchError);
  });

  it('shows an error message when WorkItemTitle emits an `error` event', async () => {
    createComponent();
    await waitForPromises();

    findWorkItemTitle().vm.$emit('error', i18n.updateError);
    await waitForPromises();

    expect(findAlert().text()).toBe(i18n.updateError);
  });

  it('calls the subscription', () => {
    createComponent();

    expect(initialSubscriptionHandler).toHaveBeenCalledWith({
      issuableId: workItemQueryResponse.data.workItem.id,
    });
  });

  describe('when work_items_mvc_2 feature flag is enabled', () => {
    it('renders assignees component when assignees widget is returned from the API', async () => {
      createComponent({
        workItemsMvc2Enabled: true,
      });
      await waitForPromises();

      expect(findWorkItemAssignees().exists()).toBe(true);
    });

    it('does not render assignees component when assignees widget is not returned from the API', async () => {
      createComponent({
        workItemsMvc2Enabled: true,
        handler: jest
          .fn()
          .mockResolvedValue(workItemResponseFactory({ assigneesWidgetPresent: false })),
      });
      await waitForPromises();

      expect(findWorkItemAssignees().exists()).toBe(false);
    });
  });

  it('does not render assignees component when assignees feature flag is disabled', async () => {
    createComponent();
    await waitForPromises();

    expect(findWorkItemAssignees().exists()).toBe(false);
  });

  describe('labels widget', () => {
    it.each`
      description                                               | includeWidgets | exists
      ${'renders when widget is returned from API'}             | ${true}        | ${true}
      ${'does not render when widget is not returned from API'} | ${false}       | ${false}
    `('$description', async ({ includeWidgets, exists }) => {
      createComponent({ includeWidgets, workItemsMvc2Enabled: true });
      await waitForPromises();

      expect(findWorkItemLabels().exists()).toBe(exists);
    });
  });

  describe('weight widget', () => {
    describe('when work_items_mvc_2 feature flag is enabled', () => {
      describe.each`
        description                               | includeWidgets | exists
        ${'when widget is returned from API'}     | ${true}        | ${true}
        ${'when widget is not returned from API'} | ${false}       | ${false}
      `('$description', ({ includeWidgets, exists }) => {
        it(`${includeWidgets ? 'renders' : 'does not render'} weight component`, async () => {
          createComponent({ includeWidgets, workItemsMvc2Enabled: true });
          await waitForPromises();

          expect(findWorkItemWeight().exists()).toBe(exists);
        });
      });
    });

    describe('when work_items_mvc_2 feature flag is disabled', () => {
      describe.each`
        description                               | includeWidgets | exists
        ${'when widget is returned from API'}     | ${true}        | ${false}
        ${'when widget is not returned from API'} | ${false}       | ${false}
      `('$description', ({ includeWidgets, exists }) => {
        it(`${includeWidgets ? 'renders' : 'does not render'} weight component`, async () => {
          createComponent({ includeWidgets, workItemsMvc2Enabled: false });
          await waitForPromises();

          expect(findWorkItemWeight().exists()).toBe(exists);
        });
      });
    });
  });

  describe('work item information', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('is visible when viewed for the first time and sets localStorage value', async () => {
      localStorage.clear();
      expect(findWorkItemInformationAlert().exists()).toBe(true);
      expect(findLocalStorageSync().props('value')).toBe(true);
    });

    it('is not visible after reading local storage input', async () => {
      await findLocalStorageSync().vm.$emit('input', false);
      expect(findWorkItemInformationAlert().exists()).toBe(false);
    });
  });
});
