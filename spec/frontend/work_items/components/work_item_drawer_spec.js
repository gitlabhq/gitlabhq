import { GlDrawer, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import WorkItemDrawer from '~/work_items/components/work_item_drawer.vue';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import deleteWorkItemMutation from '~/work_items/graphql/delete_work_item.mutation.graphql';

Vue.use(VueApollo);

const deleteWorkItemMutationHandler = jest
  .fn()
  .mockResolvedValue({ data: { workItemDelete: { errors: [] } } });

describe('WorkItemDrawer', () => {
  let wrapper;

  const mockListener = jest.fn();

  const findGlDrawer = () => wrapper.findComponent(GlDrawer);
  const findWorkItem = () => wrapper.findComponent(WorkItemDetail);

  const createComponent = ({ open = false } = {}) => {
    wrapper = shallowMount(WorkItemDrawer, {
      propsData: {
        activeItem: {
          iid: '1',
          webUrl: 'test',
        },
        open,
      },
      listeners: {
        customEvent: mockListener,
      },
      stubs: { workItemDetail: true },
      apolloProvider: createMockApollo([[deleteWorkItemMutation, deleteWorkItemMutationHandler]]),
    });
  };

  it('passes correct `open` prop to GlDrawer', () => {
    createComponent();

    expect(findGlDrawer().props('open')).toBe(false);
  });

  it('displays correct URL in link', () => {
    createComponent();

    expect(wrapper.findComponent(GlLink).attributes('href')).toBe('test');
  });

  it('emits `close` event when drawer is closed', () => {
    createComponent({ open: true });

    findGlDrawer().vm.$emit('close');

    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  it('passes listeners correctly to WorkItemDetail', () => {
    createComponent({ open: true });
    const mockPayload = { iid: '1' };

    findWorkItem().vm.$emit('customEvent', mockPayload);

    expect(mockListener).toHaveBeenCalledWith(mockPayload);
  });

  describe('when deleting work item', () => {
    it('calls deleteWorkItemMutation', () => {
      createComponent({ open: true });
      findWorkItem().vm.$emit('deleteWorkItem', { workItemId: '1' });

      expect(deleteWorkItemMutationHandler).toHaveBeenCalledWith({
        input: { id: '1' },
      });
    });

    it('emits `workItemDeleted` event when on successful mutation', async () => {
      createComponent({ open: true });
      findWorkItem().vm.$emit('deleteWorkItem', { workItemId: '1' });

      await waitForPromises();

      expect(wrapper.emitted('workItemDeleted')).toHaveLength(1);
    });

    it('emits `deleteWorkItemError` event when mutation failed', async () => {
      deleteWorkItemMutationHandler.mockRejectedValue('Houston, we have a problem');

      createComponent({ open: true });
      findWorkItem().vm.$emit('deleteWorkItem', { workItemId: '1' });

      await waitForPromises();

      expect(wrapper.emitted('deleteWorkItemError')).toHaveLength(1);
    });
  });
});
