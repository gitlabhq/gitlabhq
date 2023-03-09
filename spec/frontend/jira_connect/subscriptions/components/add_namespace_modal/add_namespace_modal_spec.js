import { shallowMount } from '@vue/test-utils';
import AddNamespaceModal from '~/jira_connect/subscriptions/components/add_namespace_modal/add_namespace_modal.vue';
import GroupsList from '~/jira_connect/subscriptions/components/add_namespace_modal/groups_list.vue';
import { ADD_NAMESPACE_MODAL_ID } from '~/jira_connect/subscriptions/constants';

describe('AddNamespaceModal', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(AddNamespaceModal);
  };

  const findModal = () => wrapper.findComponent(AddNamespaceModal);
  const findGroupsList = () => wrapper.findComponent(GroupsList);

  beforeEach(() => {
    createComponent();
  });

  it('displays modal with correct props', () => {
    const modal = findModal();
    expect(modal.exists()).toBe(true);
    expect(modal.attributes()).toMatchObject({
      modalid: ADD_NAMESPACE_MODAL_ID,
      title: AddNamespaceModal.modal.title,
    });
  });

  it('displays GroupList', () => {
    expect(findGroupsList().exists()).toBe(true);
  });
});
