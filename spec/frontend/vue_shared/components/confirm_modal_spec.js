import { shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import { merge } from 'lodash';
import { TEST_HOST } from 'helpers/test_constants';
import eventHub, { EVENT_OPEN_CONFIRM_MODAL } from '~/vue_shared/components/confirm_modal_eventhub';
import ConfirmModal from '~/vue_shared/components/confirm_modal.vue';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';

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

  const findModal = () => wrapper.findComponent(GlModalStub);
  const findForm = () => wrapper.find('form');
  const findFormData = () =>
    findForm()
      .findAll('input')
      .wrappers.map((x) => ({ name: x.attributes('name'), value: x.attributes('value') }));
  const findDomElementListener = () => wrapper.findComponent(DomElementListener);
  const triggerOpenWithEventHub = (modalData) => {
    eventHub.$emit(EVENT_OPEN_CONFIRM_MODAL, modalData);
  };
  const triggerOpenWithDomListener = (modalData) => {
    const element = document.createElement('button');

    element.dataset.path = modalData.path;
    element.dataset.method = modalData.method;
    element.dataset.modalAttributes = JSON.stringify(modalData.modalAttributes);

    findDomElementListener().vm.$emit('click', {
      preventDefault: jest.fn(),
      currentTarget: element,
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders empty GlModal', () => {
      expect(findModal().props()).toEqual({});
    });

    it('renders form missing values', () => {
      expect(findForm().attributes('action')).toBe('');
      expect(findFormData()).toEqual([
        { name: '_method', value: undefined },
        { name: 'authenticity_token', value: 'test-csrf-token' },
      ]);
    });
  });

  describe('template', () => {
    describe.each`
      desc                               | trigger
      ${'when opened from eventhub'}     | ${triggerOpenWithEventHub}
      ${'when opened from dom listener'} | ${triggerOpenWithDomListener}
    `('$desc', ({ trigger }) => {
      beforeEach(() => {
        createComponent();
        trigger(MOCK_MODAL_DATA);
      });

      it('renders GlModal with data', () => {
        expect(findModal().exists()).toBe(true);
        expect(findModal().attributes()).toEqual(
          expect.objectContaining({
            oktitle: MOCK_MODAL_DATA.modalAttributes.okTitle,
            okvariant: MOCK_MODAL_DATA.modalAttributes.okVariant,
          }),
        );
      });

      it('renders form', () => {
        expect(findForm().attributes('action')).toBe(MOCK_MODAL_DATA.path);
        expect(findFormData()).toEqual([
          { name: '_method', value: MOCK_MODAL_DATA.method },
          { name: 'authenticity_token', value: 'test-csrf-token' },
        ]);
      });
    });

    describe.each`
      desc                             | attrs                                                                         | expectation
      ${'when message is simple text'} | ${{}}                                                                         | ${`<div>${MOCK_MODAL_DATA.modalAttributes.message}</div>`}
      ${'when message has html'}       | ${{ messageHtml: '<p>Header</p><ul onhover="alert(1)"><li>First</li></ul>' }} | ${'<p>Header</p><ul><li>First</li></ul>'}
    `('$desc', ({ attrs, expectation }) => {
      beforeEach(() => {
        const modalData = merge({ ...MOCK_MODAL_DATA }, { modalAttributes: attrs });

        createComponent();
        triggerOpenWithEventHub(modalData);
      });

      it('renders message', () => {
        expect(findForm().element.innerHTML).toContain(expectation);
      });
    });
  });

  describe('when the modal has errorAlertMessage property', () => {
    beforeEach(() => {
      createComponent();
      const modalData = merge(
        { ...MOCK_MODAL_DATA },
        { modalAttributes: { errorAlertMessage: 'the alert message' } },
      );

      triggerOpenWithEventHub(modalData);
    });

    it('displays an alert component with the errorAlertMessage as the content', () => {
      const alert = wrapper.findComponent(GlAlert);

      expect(alert.props('variant')).toBe('danger');
      expect(alert.text()).toBe('the alert message');
    });
  });

  describe('methods', () => {
    describe('submitModal', () => {
      beforeEach(() => {
        createComponent();
        triggerOpenWithEventHub(MOCK_MODAL_DATA);
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
