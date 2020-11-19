import { shallowMount } from '@vue/test-utils';
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

  const popupMethods = {
    hide: jest.fn(),
    show: jest.fn(),
  };

  const GlModalStub = {
    template: '<div><slot></slot></div>',
    methods: popupMethods,
  };

  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ConfirmModal, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlModal: GlModalStub,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findModal = () => wrapper.find(GlModalStub);
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

      it('renders GlModal with data', () => {
        expect(findModal().exists()).toBeTruthy();
        expect(findModal().attributes()).toEqual(
          expect.objectContaining({
            oktitle: MOCK_MODAL_DATA.modalAttributes.okTitle,
            okvariant: MOCK_MODAL_DATA.modalAttributes.okVariant,
          }),
        );
      });
    });

    describe.each`
      desc                             | attrs                                                                         | expectation
      ${'when message is simple text'} | ${{}}                                                                         | ${`<div>${MOCK_MODAL_DATA.modalAttributes.message}</div>`}
      ${'when message has html'}       | ${{ messageHtml: '<p>Header</p><ul onhover="alert(1)"><li>First</li></ul>' }} | ${'<p>Header</p><ul><li>First</li></ul>'}
    `('$desc', ({ attrs, expectation }) => {
      beforeEach(() => {
        createComponent();
        wrapper.vm.modalAttributes = {
          ...MOCK_MODAL_DATA.modalAttributes,
          ...attrs,
        };
      });

      it('renders message', () => {
        expect(findForm().element.innerHTML).toContain(expectation);
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

      describe('with handleSubmit prop', () => {
        const handleSubmit = jest.fn();
        beforeEach(() => {
          createComponent({ handleSubmit });
          findModal().vm.$emit('primary');
        });

        it('will call handleSubmit', () => {
          expect(handleSubmit).toHaveBeenCalled();
        });

        it('does not submit the form', () => {
          expect(findForm().element.submit).not.toHaveBeenCalled();
        });
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
        expect(popupMethods.hide).not.toHaveBeenCalled();
      });

      describe('when modal closed', () => {
        beforeEach(() => {
          findModal().vm.$emit('cancel');
        });

        it('closes modal', () => {
          expect(popupMethods.hide).toHaveBeenCalled();
        });
      });
    });
  });
});
