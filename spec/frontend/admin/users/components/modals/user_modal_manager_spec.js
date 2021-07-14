import { mount } from '@vue/test-utils';
import UserModalManager from '~/admin/users/components/modals/user_modal_manager.vue';
import ModalStub from './stubs/modal_stub';

describe('Users admin page Modal Manager', () => {
  let wrapper;

  const modalConfiguration = {
    action1: {
      title: 'action1',
      content: 'Action Modal 1',
    },
    action2: {
      title: 'action2',
      content: 'Action Modal 2',
    },
  };

  const findModal = () => wrapper.find({ ref: 'modal' });

  const createComponent = (props = {}) => {
    wrapper = mount(UserModalManager, {
      propsData: {
        selector: '.js-delete-user-modal-button',
        modalConfiguration,
        csrfToken: 'dummyCSRF',
        ...props,
      },
      stubs: {
        DeleteUserModal: ModalStub,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('render behavior', () => {
    it('does not renders modal when initialized', () => {
      createComponent();
      expect(findModal().exists()).toBeFalsy();
    });

    it('throws if action has no proper configuration', () => {
      createComponent({
        modalConfiguration: {},
      });
      expect(() => wrapper.vm.show({ glModalAction: 'action1' })).toThrow();
    });

    it('renders modal with expected props when valid configuration is passed', () => {
      createComponent();
      wrapper.vm.show({
        glModalAction: 'action1',
        extraProp: 'extraPropValue',
      });

      return wrapper.vm.$nextTick().then(() => {
        const modal = findModal();
        expect(modal.exists()).toBeTruthy();
        expect(modal.vm.$attrs.csrfToken).toEqual('dummyCSRF');
        expect(modal.vm.$attrs.extraProp).toEqual('extraPropValue');
        expect(modal.vm.showWasCalled).toBeTruthy();
      });
    });
  });

  describe('click handling', () => {
    let button;
    let button2;

    const createButtons = () => {
      button = document.createElement('button');
      button2 = document.createElement('button');
      button.setAttribute('class', 'js-delete-user-modal-button');
      button.setAttribute('data-username', 'foo');
      button.setAttribute('data-gl-modal-action', 'action1');
      button.setAttribute('data-block-user-url', '/block');
      button.setAttribute('data-delete-user-url', '/delete');
      document.body.appendChild(button);
      document.body.appendChild(button2);
    };
    const removeButtons = () => {
      button.remove();
      button = null;
      button2.remove();
      button2 = null;
    };

    beforeEach(() => {
      createButtons();
      createComponent();
    });

    afterEach(() => {
      removeButtons();
    });

    it('renders the modal when the button is clicked', async () => {
      button.click();

      await wrapper.vm.$nextTick();

      expect(findModal().exists()).toBe(true);
    });

    it('does not render the modal when a misconfigured button is clicked', async () => {
      button.removeAttribute('data-gl-modal-action');
      button.click();

      await wrapper.vm.$nextTick();

      expect(findModal().exists()).toBe(false);
    });

    it('does not render the modal when a button without the selector class is clicked', async () => {
      button2.click();

      await wrapper.vm.$nextTick();

      expect(findModal().exists()).toBe(false);
    });
  });
});
