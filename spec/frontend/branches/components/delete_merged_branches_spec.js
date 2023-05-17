import { GlDisclosureDropdown, GlButton, GlFormInput, GlModal, GlSprintf } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import DeleteMergedBranches, { i18n } from '~/branches/components/delete_merged_branches.vue';
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
  wrapper.findComponent('[data-qa-selector="delete_merged_branches_button"]');
const findModal = () => wrapper.findComponent(GlModal);
const findConfirmationButton = () =>
  wrapper.findByTestId('delete-merged-branches-confirmation-button');
const findCancelButton = () => wrapper.findByTestId('delete-merged-branches-cancel-button');
const findFormInput = () => wrapper.findComponent(GlFormInput);
const findForm = () => wrapper.find('form');
const submitFormSpy = () => jest.spyOn(wrapper.vm.$refs.form, 'submit');

describe('Delete merged branches component', () => {
  beforeEach(() => {
    createComponent();
  });

  describe('Delete merged branches button', () => {
    it('has correct text', () => {
      createComponent(mount, stubsData);
      expect(findDeleteButton().text()).toBe(i18n.deleteButtonText);
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
      expect(findModal().props('title')).toBe(i18n.modalTitle);
      expect(modalText).toContain(i18n.notVisibleBranchesWarning);
      expect(modalText).toContain(i18n.protectedBranchWarning);
    });

    it('renders confirm and cancel buttons with correct text', () => {
      expect(findConfirmationButton().text()).toContain(i18n.deleteButtonText);
      expect(findCancelButton().text()).toContain(i18n.cancelButtonText);
    });

    it('renders form with correct attributes and hiden inputs', () => {
      const form = findForm();
      expect(form.attributes()).toEqual({
        action: formPath,
        method: 'post',
      });
      expect(form.find('input[name="_method"]').attributes('value')).toBe('delete');
      expect(form.find('input[name="authenticity_token"]').attributes('value')).toBe(
        'mock-csrf-token',
      );
    });

    it('matches snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('has a disabled confirm button by default', () => {
      expect(findConfirmationButton().props('disabled')).toBe(true);
    });

    it('keeps disabled state when wrong input is provided', async () => {
      findFormInput().vm.$emit('input', 'hello');
      await waitForPromises();
      expect(findConfirmationButton().props('disabled')).toBe(true);
      findConfirmationButton().trigger('click');

      expect(submitFormSpy()).not.toHaveBeenCalled();
      findFormInput().trigger('keyup.enter');

      expect(submitFormSpy()).not.toHaveBeenCalled();
    });

    it('submits form when correct amount is provided and the confirm button is clicked', async () => {
      findFormInput().vm.$emit('input', 'delete');
      await waitForPromises();
      findConfirmationButton().trigger('click');
      expect(submitFormSpy()).toHaveBeenCalled();
    });

    it('calls hide on the modal when cancel button is clicked', () => {
      findCancelButton().trigger('click');
      expect(modalHideSpy).toHaveBeenCalled();
    });
  });
});
