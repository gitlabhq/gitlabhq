import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AddNamespaceButton from '~/jira_connect/subscriptions/components/add_namespace_button.vue';
import AddNamespaceModal from '~/jira_connect/subscriptions/components/add_namespace_modal/add_namespace_modal.vue';
import { ADD_NAMESPACE_MODAL_ID } from '~/jira_connect/subscriptions/constants';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('AddNamespaceButton', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(AddNamespaceButton, {
      directives: {
        glModal: createMockDirective('gl-modal'),
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(AddNamespaceModal);

  beforeEach(() => {
    createComponent();
  });

  it('displays a button', () => {
    expect(findButton().exists()).toBe(true);
  });

  it('contains a modal', () => {
    expect(findModal().exists()).toBe(true);
  });

  it('button is bound to the modal', () => {
    const { value } = getBinding(findButton().element, 'gl-modal');

    expect(value).toBe(ADD_NAMESPACE_MODAL_ID);
  });
});
