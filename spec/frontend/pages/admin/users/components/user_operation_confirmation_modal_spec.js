import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import UserOperationConfirmationModal from '~/pages/admin/users/components/user_operation_confirmation_modal.vue';

describe('User Operation confirmation modal', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(UserOperationConfirmationModal, {
      propsData: {
        title: 'title',
        content: 'content',
        action: 'action',
        url: '/url',
        username: 'username',
        csrfToken: 'csrf',
        method: 'method',
        ...props,
      },
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

  it('closing modal with ok button triggers form submit', () => {
    createComponent();
    const form = wrapper.find('form');
    jest.spyOn(form.element, 'submit').mockReturnValue();
    wrapper.find(GlModal).vm.$emit('ok');
    return wrapper.vm.$nextTick().then(() => {
      expect(form.element.submit).toHaveBeenCalled();
      expect(form.element.action).toContain(wrapper.props('url'));
      expect(new FormData(form.element).get('authenticity_token')).toEqual(
        wrapper.props('csrfToken'),
      );
    });
  });
});
