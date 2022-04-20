import { GlDropdownItem, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import WorkItemActions from '~/work_items/components/work_item_actions.vue';
import deleteWorkItem from '~/work_items/graphql/delete_work_item.mutation.graphql';
import { deleteWorkItemResponse, deleteWorkItemFailureResponse } from '../mock_data';

describe('WorkItemActions component', () => {
  let wrapper;
  let glModalDirective;

  Vue.use(VueApollo);

  const findModal = () => wrapper.findComponent(GlModal);
  const findDeleteButton = () => wrapper.findComponent(GlDropdownItem);

  const createComponent = ({
    canUpdate = true,
    deleteWorkItemHandler = jest.fn().mockResolvedValue(deleteWorkItemResponse),
  } = {}) => {
    glModalDirective = jest.fn();
    wrapper = shallowMount(WorkItemActions, {
      apolloProvider: createMockApollo([[deleteWorkItem, deleteWorkItemHandler]]),
      propsData: { workItemId: '123', canUpdate },
      directives: {
        glModal: {
          bind(_, { value }) {
            glModalDirective(value);
          },
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders modal', () => {
    createComponent();

    expect(findModal().exists()).toBe(true);
    expect(findModal().props('visible')).toBe(false);
  });

  it('shows confirm modal when clicking Delete work item', () => {
    createComponent();

    findDeleteButton().vm.$emit('click');

    expect(glModalDirective).toHaveBeenCalled();
  });

  it('calls delete mutation when clicking OK button', () => {
    const deleteWorkItemHandler = jest.fn().mockResolvedValue(deleteWorkItemResponse);

    createComponent({
      deleteWorkItemHandler,
    });

    findModal().vm.$emit('ok');

    expect(deleteWorkItemHandler).toHaveBeenCalled();
    expect(wrapper.emitted('error')).toBeUndefined();
  });

  it('emits event after delete success', async () => {
    createComponent();

    findModal().vm.$emit('ok');

    await waitForPromises();

    expect(wrapper.emitted('workItemDeleted')).not.toBeUndefined();
    expect(wrapper.emitted('error')).toBeUndefined();
  });

  it('emits error event after delete failure', async () => {
    createComponent({
      deleteWorkItemHandler: jest.fn().mockResolvedValue(deleteWorkItemFailureResponse),
    });

    findModal().vm.$emit('ok');

    await waitForPromises();

    expect(wrapper.emitted('error')[0]).toEqual([
      "The resource that you are attempting to access does not exist or you don't have permission to perform this action",
    ]);
    expect(wrapper.emitted('workItemDeleted')).toBeUndefined();
  });

  it('does not render when canUpdate is false', () => {
    createComponent({
      canUpdate: false,
    });

    expect(wrapper.html()).toBe('');
  });
});
