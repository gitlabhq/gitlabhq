import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import SharedDeleteButton from '~/projects/components/shared/delete_button.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'test-csrf-token' }));

describe('Project remove modal', () => {
  let wrapper;

  const findFormElement = () => wrapper.find('form');
  const findConfirmButton = () => wrapper.find('.js-modal-action-primary');
  const findAuthenticityTokenInput = () => findFormElement().find('input[name=authenticity_token]');
  const findModal = () => wrapper.find(GlModal);

  const defaultProps = {
    confirmPhrase: 'foo',
    formPath: 'some/path',
  };

  const createComponent = (data = {}, stubs = {}) => {
    wrapper = shallowMount(SharedDeleteButton, {
      propsData: defaultProps,
      data: () => data,
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: `
            <div>
              <slot name="modal-title"></slot>
              <slot></slot>
            </div>`,
        }),
        ...stubs,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('intialized', () => {
    beforeEach(() => {
      createComponent();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('sets a csrf token on the authenticity form input', () => {
      expect(findAuthenticityTokenInput().element.value).toEqual('test-csrf-token');
    });

    it('sets the form action to the provided path', () => {
      expect(findFormElement().attributes('action')).toEqual(defaultProps.formPath);
    });
  });

  describe('when the user input does not match the confirmPhrase', () => {
    beforeEach(() => {
      createComponent({ userInput: 'bar' }, { GlModal });
    });

    it('the confirm button is disabled', () => {
      expect(findConfirmButton().attributes('disabled')).toBe('true');
    });
  });

  describe('when the user input matches the confirmPhrase', () => {
    beforeEach(() => {
      createComponent({ userInput: defaultProps.confirmPhrase }, { GlModal });
    });

    it('the confirm button is not disabled', () => {
      expect(findConfirmButton().attributes('disabled')).toBe(undefined);
    });
  });

  describe('when the modal is confirmed', () => {
    beforeEach(() => {
      createComponent();
      findModal().vm.$emit('ok');
    });

    it('submits the form element', () => {
      expect(findFormElement().element.submit).toHaveBeenCalled();
    });
  });
});
