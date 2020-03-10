import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import ConfirmModal from '~/vue_shared/components/confirm_modal.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'test-csrf-token' }));

describe('vue_shared/components/confirm_modal', () => {
  const MOCK_MODAL_DATA = {
    path: `${TEST_HOST}/1`,
    method: 'delete',
    modalAttributes: {
      title: 'Are you sure?',
      message: 'This will remove item 1',
      okVariant: 'danger',
      okTitle: 'Remove item',
    },
  };

  const defaultProps = {
    selector: '.test-button',
  };

  const actionSpies = {
    openModal: jest.fn(),
    closeModal: jest.fn(),
  };

  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ConfirmModal, {
      propsData: {
        ...defaultProps,
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
  const findForm = () => wrapper.find('form');
  const findFormData = () =>
    findForm()
      .findAll('input')
      .wrappers.map(x => ({ name: x.attributes('name'), value: x.attributes('value') }));

  describe('template', () => {
    describe('when modal data is set', () => {
      beforeEach(() => {
        createComponent();
        wrapper.vm.modalAttributes = MOCK_MODAL_DATA.modalAttributes;
      });

      it('renders GlModal wtih data', () => {
        expect(findModal().exists()).toBeTruthy();
        expect(findModal().attributes()).toEqual(
          expect.objectContaining({
            oktitle: MOCK_MODAL_DATA.modalAttributes.okTitle,
            okvariant: MOCK_MODAL_DATA.modalAttributes.okVariant,
          }),
        );
      });
    });
  });

  describe('methods', () => {
    describe('submitModal', () => {
      beforeEach(() => {
        createComponent();
        wrapper.vm.path = MOCK_MODAL_DATA.path;
        wrapper.vm.method = MOCK_MODAL_DATA.method;
      });

      it('does not submit form', () => {
        expect(findForm().element.submit).not.toHaveBeenCalled();
      });

      describe('when modal submitted', () => {
        beforeEach(() => {
          findModal().vm.$emit('primary');
        });

        it('submits form', () => {
          expect(findFormData()).toEqual([
            { name: '_method', value: MOCK_MODAL_DATA.method },
            { name: 'authenticity_token', value: 'test-csrf-token' },
          ]);
          expect(findForm().element.submit).toHaveBeenCalled();
        });
      });
    });

    describe('closeModal', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not close modal', () => {
        expect(actionSpies.closeModal).not.toHaveBeenCalled();
      });

      describe('when modal closed', () => {
        beforeEach(() => {
          findModal().vm.$emit('cancel');
        });

        it('closes modal', () => {
          expect(actionSpies.closeModal).toHaveBeenCalled();
        });
      });
    });
  });
});
