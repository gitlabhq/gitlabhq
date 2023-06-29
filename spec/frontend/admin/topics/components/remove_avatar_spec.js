import { GlButton, GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import RemoveAvatar from '~/admin/topics/components/remove_avatar.vue';

const modalID = 'fake-id';
const path = 'topic/path/1';
const name = 'Topic 1';

jest.mock('lodash/uniqueId', () => () => 'fake-id');
jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('RemoveAvatar', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(RemoveAvatar, {
      provide: {
        path,
        name,
      },
      directives: {
        GlModal: createMockDirective('gl-modal'),
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.find('form');

  beforeEach(() => {
    createComponent();
  });

  describe('the button component', () => {
    it('displays the remove button', () => {
      const button = findButton();

      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Remove avatar');
    });

    it('contains the correct modal ID', () => {
      const buttonModalId = getBinding(findButton().element, 'gl-modal').value;

      expect(buttonModalId).toBe(modalID);
    });
  });

  describe('the modal component', () => {
    it('displays the modal component', () => {
      const modal = findModal();

      expect(modal.exists()).toBe(true);
      expect(modal.props('title')).toBe('Remove topic avatar');
      expect(modal.text()).toBe(`Topic avatar for ${name} will be removed. This cannot be undone.`);
    });

    it('contains the correct modal ID', () => {
      expect(findModal().props('modalId')).toBe(modalID);
    });

    describe('form', () => {
      it('matches the snapshot', () => {
        expect(findForm().element).toMatchSnapshot();
      });

      describe('form submission', () => {
        let formSubmitSpy;

        beforeEach(() => {
          formSubmitSpy = jest.spyOn(findForm().element, 'submit');
          findModal().vm.$emit('primary');
        });

        it('submits the form on the modal primary action', () => {
          expect(formSubmitSpy).toHaveBeenCalled();
        });
      });
    });
  });
});
