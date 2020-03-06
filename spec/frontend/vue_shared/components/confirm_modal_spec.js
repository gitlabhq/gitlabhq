import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import ConfirmModal from '~/vue_shared/components/confirm_modal.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'test-csrf-token' }));

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
  const findForm = () => wrapper.find('form');
  const findFormData = () =>
    findForm()
      .findAll('input')
      .wrappers.map(x => ({ name: x.attributes('name'), value: x.attributes('value') }));

  describe('template', () => {
    describe('when showModal is false', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not render GlModal', () => {
        expect(findModal().exists()).toBeFalsy();
      });
    });

    describe('when showModal is true', () => {
      beforeEach(() => {
        createComponent({ showModal: true });
      });

      it('renders GlModal', () => {
        expect(findModal().exists()).toBeTruthy();
        expect(findModal().attributes()).toEqual(
          expect.objectContaining({
            modalid: testModalProps.modalAttributes.modalId,
            oktitle: testModalProps.modalAttributes.okTitle,
            okvariant: testModalProps.modalAttributes.okVariant,
          }),
        );
      });
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      createComponent({ showModal: true });
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
          { name: '_method', value: testModalProps.method },
          { name: 'authenticity_token', value: 'test-csrf-token' },
        ]);
        expect(findForm().element.submit).toHaveBeenCalled();
      });
    });
  });
});
