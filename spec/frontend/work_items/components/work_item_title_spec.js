import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ItemTitle from '~/work_items/components/item_title.vue';
import WorkItemTitle from '~/work_items/components/work_item_title.vue';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { updateWorkItemMutationResponse, workItemQueryResponse } from '../mock_data';

describe('WorkItemTitle component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const mutationSuccessHandler = jest.fn().mockResolvedValue(updateWorkItemMutationResponse);

  const findItemTitle = () => wrapper.findComponent(ItemTitle);

  const createComponent = ({ mutationHandler = mutationSuccessHandler, canUpdate = true } = {}) => {
    const { id, title, workItemType } = workItemQueryResponse.data.workItem;
    wrapper = shallowMount(WorkItemTitle, {
      apolloProvider: createMockApollo([[updateWorkItemMutation, mutationHandler]]),
      propsData: {
        workItemId: id,
        workItemTitle: title,
        workItemType: workItemType.name,
        canUpdate,
      },
    });
  };

  it('renders title', () => {
    createComponent();

    expect(findItemTitle().props('title')).toBe(workItemQueryResponse.data.workItem.title);
  });

  describe('item title disabled prop', () => {
    describe.each`
      description             | canUpdate | value
      ${'when cannot update'} | ${false}  | ${true}
      ${'when can update'}    | ${true}   | ${false}
    `('$description', ({ canUpdate, value }) => {
      it(`renders item title component with disabled=${value}`, () => {
        createComponent({ canUpdate });

        expect(findItemTitle().props('disabled')).toBe(value);
      });
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

      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong while updating the task. Please try again.'],
      ]);
    });

    it('tracks editing the title', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      createComponent();

      findItemTitle().vm.$emit('title-changed', 'new title');
      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'updated_title', {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_title',
        property: 'type_Task',
      });
    });

    describe('when title has more than 255 characters', () => {
      const title = new Array(257).join('a');

      it('does not call a mutation', () => {
        createComponent();

        findItemTitle().vm.$emit('title-changed', title);

        expect(mutationSuccessHandler).not.toHaveBeenCalled();
      });

      it('emits an error message', () => {
        createComponent();

        findItemTitle().vm.$emit('title-changed', title);

        expect(wrapper.emitted('error')).toEqual([['Title cannot have more than 255 characters.']]);
      });
    });
  });
});
