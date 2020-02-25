import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import ConfirmModal from '~/vue_shared/components/confirm_modal.vue';

describe('vue_shared/components/confirm_modal', () => {
  const testModalProps = {
    path: `${TEST_HOST}/1`,
    method: 'delete',
    modalAttributes: {
      modalId: 'test-confirm-modal',
      title: 'Are you sure?',
      message: 'This will remove item 1',
      okVariant: 'danger',
      okTitle: 'Remove item',
    },
  };

  const actionSpies = {
    openModal: jest.fn(),
  };

  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ConfirmModal, {
      propsData: {
        ...testModalProps,
        ...props,
      },
      methods: {
        ...actionSpies,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findModal = () => wrapper.find(GlModal);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('calls openModal on mount', () => {
      expect(actionSpies.openModal).toHaveBeenCalled();
    });

    it('renders GlModal', () => {
      expect(findModal().exists()).toBeTruthy();
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('submitModal', () => {
      beforeEach(() => {
        wrapper.vm.$refs.form.requestSubmit = jest.fn();
      });

      it('calls requestSubmit', () => {
        wrapper.vm.submitModal();
        expect(wrapper.vm.$refs.form.requestSubmit).toHaveBeenCalled();
      });
    });

    describe('dismiss', () => {
      it('removes gl-modal', () => {
        expect(findModal().exists()).toBeTruthy();
        wrapper.vm.dismiss();

        return wrapper.vm.$nextTick(() => {
          expect(findModal().exists()).toBeFalsy();
        });
      });
    });
  });
});
