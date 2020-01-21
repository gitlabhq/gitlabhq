import { mount } from '@vue/test-utils';
import UserModalManager from '~/pages/admin/users/components/user_modal_manager.vue';
import ModalStub from './stubs/modal_stub';

describe('Users admin page Modal Manager', () => {
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

  const actionModals = {
    action1: ModalStub,
    action2: ModalStub,
  };

  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(UserModalManager, {
      propsData: {
        actionModals,
        modalConfiguration,
        csrfToken: 'dummyCSRF',
        ...props,
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
      expect(wrapper.find({ ref: 'modal' }).exists()).toBeFalsy();
    });

    it('throws if non-existing action is requested', () => {
      createComponent();
      expect(() => wrapper.vm.show({ glModalAction: 'non-existing' })).toThrow();
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
        const modal = wrapper.find({ ref: 'modal' });
        expect(modal.exists()).toBeTruthy();
        expect(modal.vm.$attrs.csrfToken).toEqual('dummyCSRF');
        expect(modal.vm.$attrs.extraProp).toEqual('extraPropValue');
        expect(modal.vm.showWasCalled).toBeTruthy();
      });
    });
  });

  describe('global listener', () => {
    beforeEach(() => {
      jest.spyOn(document, 'addEventListener');
      jest.spyOn(document, 'removeEventListener');
    });

    afterAll(() => {
      jest.restoreAllMocks();
    });

    it('registers global listener on mount', () => {
      createComponent();
      expect(document.addEventListener).toHaveBeenCalledWith('click', expect.any(Function));
    });

    it('removes global listener on destroy', () => {
      createComponent();
      wrapper.destroy();
      expect(document.removeEventListener).toHaveBeenCalledWith('click', expect.any(Function));
    });
  });

  describe('click handling', () => {
    let node;

    beforeEach(() => {
      node = document.createElement('div');
      document.body.appendChild(node);
    });

    afterEach(() => {
      node.remove();
      node = null;
    });

    it('ignores wrong clicks', () => {
      createComponent();
      const event = new window.MouseEvent('click', {
        bubbles: true,
        cancellable: true,
      });
      jest.spyOn(event, 'preventDefault');
      node.dispatchEvent(event);
      expect(event.preventDefault).not.toHaveBeenCalled();
    });

    it('captures click with glModalAction', () => {
      createComponent();
      node.dataset.glModalAction = 'action1';
      const event = new window.MouseEvent('click', {
        bubbles: true,
        cancellable: true,
      });
      jest.spyOn(event, 'preventDefault');
      node.dispatchEvent(event);

      expect(event.preventDefault).toHaveBeenCalled();
      return wrapper.vm.$nextTick().then(() => {
        const modal = wrapper.find({ ref: 'modal' });
        expect(modal.exists()).toBeTruthy();
        expect(modal.vm.showWasCalled).toBeTruthy();
      });
    });
  });
});
