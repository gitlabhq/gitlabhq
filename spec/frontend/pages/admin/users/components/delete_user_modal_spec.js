import { shallowMount } from '@vue/test-utils';
import { GlButton, GlFormInput } from '@gitlab/ui';
import DeleteUserModal from '~/pages/admin/users/components/delete_user_modal.vue';
import ModalStub from './stubs/modal_stub';

describe('User Operation confirmation modal', () => {
  let wrapper;

  const findButton = variant =>
    wrapper
      .findAll(GlButton)
      .filter(w => w.attributes('variant') === variant)
      .at(0);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DeleteUserModal, {
      propsData: {
        title: 'title',
        content: 'content',
        action: 'action',
        secondaryAction: 'secondaryAction',
        deleteUserUrl: 'delete-url',
        blockUserUrl: 'block-url',
        username: 'username',
        csrfToken: 'csrf',
        ...props,
      },
      stubs: {
        GlModal: ModalStub,
      },
      sync: false,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders modal with form included', () => {
    createComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  it.each`
    variant      | prop               | action
    ${'danger'}  | ${'deleteUserUrl'} | ${'delete'}
    ${'warning'} | ${'blockUserUrl'}  | ${'block'}
  `('closing modal with $variant button triggers $action', ({ variant, prop }) => {
    createComponent();
    const form = wrapper.find('form');
    jest.spyOn(form.element, 'submit').mockReturnValue();
    const modalButton = findButton(variant);
    modalButton.vm.$emit('click');
    return wrapper.vm.$nextTick().then(() => {
      expect(form.element.submit).toHaveBeenCalled();
      expect(form.element.action).toContain(wrapper.props(prop));
      expect(new FormData(form.element).get('authenticity_token')).toEqual(
        wrapper.props('csrfToken'),
      );
    });
  });

  it('disables buttons by default', () => {
    createComponent();
    const blockButton = findButton('warning');
    const deleteButton = findButton('danger');
    expect(blockButton.attributes().disabled).toBeTruthy();
    expect(deleteButton.attributes().disabled).toBeTruthy();
  });

  it('enables button when username is typed', () => {
    createComponent({
      username: 'some-username',
    });
    wrapper.find(GlFormInput).vm.$emit('input', 'some-username');
    const blockButton = findButton('warning');
    const deleteButton = findButton('danger');

    return wrapper.vm.$nextTick().then(() => {
      expect(blockButton.attributes().disabled).toBeFalsy();
      expect(deleteButton.attributes().disabled).toBeFalsy();
    });
  });
});
