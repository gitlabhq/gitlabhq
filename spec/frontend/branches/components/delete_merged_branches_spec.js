import { nextTick } from 'vue';
import { GlDisclosureDropdown, GlButton, GlFormInput, GlModal, GlSprintf } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import DeleteMergedBranches from '~/branches/components/delete_merged_branches.vue';
import { formPath, propsDataMock } from '../mock_data';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

let wrapper;
const modalShowSpy = jest.fn();
const modalHideSpy = jest.fn();

const stubsData = {
  GlModal: stubComponent(GlModal, {
    template:
      '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
    methods: {
      show: modalShowSpy,
      hide: modalHideSpy,
    },
  }),
  GlDisclosureDropdown,
  GlButton,
  GlFormInput,
  GlSprintf,
};

const createComponent = (mountFn = shallowMountExtended, stubs = {}) => {
  wrapper = mountFn(DeleteMergedBranches, {
    propsData: {
      ...propsDataMock,
    },
    stubs,
  });
};

const findDeleteButton = () =>
  wrapper.findComponent('[data-testid="delete-merged-branches-button"]');
const findModal = () => wrapper.findComponent(GlModal);
const findConfirmationButton = () =>
  wrapper.findByTestId('delete-merged-branches-confirmation-button');
const findCancelButton = () => wrapper.findByTestId('delete-merged-branches-cancel-button');
const findFormInput = () => wrapper.findComponent(GlFormInput);
const findForm = () => wrapper.find('form');

describe('Delete merged branches component', () => {
  beforeEach(() => {
    createComponent();
  });

  describe('Delete merged branches button', () => {
    it('has correct text', () => {
      createComponent(mount, stubsData);
      expect(findDeleteButton().text()).toBe('Delete merged branches');
    });

    it('opens modal when clicked', () => {
      createComponent(mount, stubsData);
      findDeleteButton().trigger('click');

      expect(modalShowSpy).toHaveBeenCalled();
    });
  });

  describe('Delete merged branches confirmation modal', () => {
    beforeEach(() => {
      createComponent(shallowMountExtended, stubsData);
    });

    it('renders correct modal title and text', () => {
      const modalText = findModal().text();
      expect(findModal().props('title')).toBe('Delete all merged branches?');
      expect(modalText).toContain(
        'This may include merged branches that are not visible on the current screen.',
      );
      expect(modalText).toContain(
        "A branch won't be deleted if it is protected or associated with an open merge request.",
      );
      expect(modalText).toContain(
        'This bulk action is permanent and cannot be undone or recovered',
      );
      expect(modalText).toContain('Please type the following to confirm: delete.');
    });

    it('renders confirm and cancel buttons with correct text', () => {
      expect(findConfirmationButton().text()).toBe('Delete merged branches');
      expect(findCancelButton().text()).toBe('Cancel');
    });

    it('renders form with correct attributes and hidden inputs', () => {
      const form = findForm();
      expect(form.attributes()).toEqual({
        action: formPath,
        id: 'delete-merged-branches-form',
        method: 'post',
      });
      expect(form.find('input[name="_method"]').attributes('value')).toBe('delete');
      expect(form.find('input[name="authenticity_token"]').attributes('value')).toBe(
        'mock-csrf-token',
      );
    });

    it('has a disabled confirm button by default', () => {
      expect(findConfirmationButton().props('disabled')).toBe(true);
    });

    it('keeps disabled state when wrong input is provided', async () => {
      findFormInput().vm.$emit('input', 'hello');
      await nextTick();
      expect(findConfirmationButton().props('disabled')).toBe(true);
    });

    it('enables the button when correct input is provided', async () => {
      findFormInput().vm.$emit('input', 'delete');
      await nextTick();
      expect(findConfirmationButton().props('disabled')).toBe(false);
    });

    it('calls hide on the modal when cancel button is clicked', () => {
      findCancelButton().vm.$emit('click');

      expect(modalHideSpy).toHaveBeenCalled();
    });

    it('resets the input field when the modal is closed', async () => {
      const inputValue = 'hello';
      findFormInput().vm.$emit('input', inputValue);
      await nextTick();
      expect(findFormInput().props('value')).toBe(inputValue);
      await findModal().vm.$emit('hidden');
      expect(findFormInput().props('value')).toBe('');
    });
  });
});
