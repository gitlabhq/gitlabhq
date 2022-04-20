import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ItemTitle from '~/work_items/components/item_title.vue';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import { i18n } from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { updateWorkItemMutationResponse, workItemQueryResponse } from '../mock_data';

describe('WorkItemTitle component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const mutationSuccessHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findItemTitle = () => wrapper.findComponent(ItemTitle);

  const createComponent = ({ loading = false, mutationHandler = mutationSuccessHandler } = {}) => {
    const { id, title, workItemType } = workItemQueryResponse.data.workItem;
    wrapper = shallowMount(WorkItemTitle, {
      apolloProvider: createMockApollo([[updateWorkItemMutation, mutationHandler]]),
      propsData: {
        loading,
        workItemId: id,
        workItemTitle: title,
        workItemType: workItemType.name,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('renders loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render title', () => {
      expect(findItemTitle().exists()).toBe(false);
    });
  });

  describe('when loaded', () => {
    beforeEach(() => {
      createComponent({ loading: false });
    });

    it('does not render loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders title', () => {
      expect(findItemTitle().props('title')).toBe(workItemQueryResponse.data.workItem.title);
    });
  });

  describe('when updating the title', () => {
    it('calls a mutation', () => {
      const title = 'new title!';

      createComponent();

      findItemTitle().vm.$emit('title-changed', title);

      expect(mutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          id: workItemQueryResponse.data.workItem.id,
          title,
        },
      });
    });

    it('does not call a mutation when the title has not changed', () => {
      createComponent();

      findItemTitle().vm.$emit('title-changed', workItemQueryResponse.data.workItem.title);

      expect(mutationSuccessHandler).not.toHaveBeenCalled();
    });

    it('emits an error message when the mutation was unsuccessful', async () => {
      createComponent({ mutationHandler: jest.fn().mockRejectedValue('Error!') });

      findItemTitle().vm.$emit('title-changed', 'new title');
      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([[i18n.updateError]]);
    });

    it('tracks editing the title', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      createComponent();

      findItemTitle().vm.$emit('title-changed', 'new title');
      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith('workItems:show', 'updated_title', {
        category: 'workItems:show',
        label: 'item_title',
        property: 'type_Task',
      });
    });
  });
});
