import { GlModal, GlForm, GlFormCheckbox, GlSprintf } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import { shallowMount, mount, createWrapper } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import BranchesDropdown from '~/projects/commit/components/branches_dropdown.vue';
import CommitFormModal from '~/projects/commit/components/form_modal.vue';
import ProjectsDropdown from '~/projects/commit/components/projects_dropdown.vue';
import eventHub from '~/projects/commit/event_hub';
import createStore from '~/projects/commit/store';
import mockData from '../mock_data';

describe('CommitFormModal', () => {
  let wrapper;
  let store;
  let axiosMock;

  const createComponent = (method, state = {}, provide = {}, propsData = {}) => {
    store = createStore({ ...mockData.mockModal, ...state });
    wrapper = extendedWrapper(
      method(CommitFormModal, {
        provide: {
          ...provide,
        },
        propsData: { ...mockData.modalPropsData, ...propsData },
        store,
        attrs: {
          static: true,
          visible: true,
        },
      }),
    );
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findStartBranch = () => wrapper.find('#start_branch');
  const findTargetProject = () => wrapper.find('#target_project_id');
  const findBranchesDropdown = () => wrapper.findComponent(BranchesDropdown);
  const findProjectsDropdown = () => wrapper.findComponent(ProjectsDropdown);
  const findForm = () => findModal().findComponent(GlForm);
  const findCheckBox = () => findForm().findComponent(GlFormCheckbox);
  const findPrependedText = () => wrapper.findByTestId('prepended-text');
  const findAppendedText = () => wrapper.findByTestId('appended-text');
  const getByText = (text, options) =>
    createWrapper(within(findModal().element).getByText(text, options));

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    axiosMock.restore();
  });

  describe('Basic interactions', () => {
    it('Listens for opening of modal on mount', () => {
      jest.spyOn(eventHub, '$on');

      createComponent(shallowMount);

      expect(eventHub.$on).toHaveBeenCalledWith(mockData.modalPropsData.openModal, wrapper.vm.show);
    });

    it('Shows modal', () => {
      createComponent(shallowMount);
      const rootEmit = jest.spyOn(wrapper.vm.$root, '$emit');

      wrapper.vm.show();

      expect(rootEmit).toHaveBeenCalledWith(BV_SHOW_MODAL, mockData.modalPropsData.modalId);
    });

    it('Clears the modal state once modal is hidden', () => {
      createComponent(shallowMount);
      jest.spyOn(store, 'dispatch').mockImplementation();
      wrapper.vm.checked = false;

      findModal().vm.$emit('hidden');

      expect(store.dispatch).toHaveBeenCalledWith('clearModal');
      expect(store.dispatch).toHaveBeenCalledWith('setSelectedBranch', '');
      expect(wrapper.vm.checked).toBe(true);
    });

    it('Shows the checkbox for new merge request', () => {
      createComponent(shallowMount);

      expect(findCheckBox().exists()).toBe(true);
    });

    it('Shows the prepended text', () => {
      createComponent(shallowMount, {}, { prependedText: '_prepended_text_' });

      expect(findPrependedText().exists()).toBe(true);
      expect(findPrependedText().find(GlSprintf).attributes('message')).toBe('_prepended_text_');
    });

    it('Does not show prepended text', () => {
      createComponent(shallowMount);

      expect(findPrependedText().exists()).toBe(false);
    });

    it('Does not show extra message text', () => {
      createComponent(shallowMount);

      expect(findModal().find('[data-testid="appended-text"]').exists()).toBe(false);
    });

    it('Does not show the checkbox for new merge request', () => {
      createComponent(shallowMount, { pushCode: false });

      expect(findCheckBox().exists()).toBe(false);
    });

    it('Shows the branch in fork message', () => {
      createComponent(shallowMount, { pushCode: false });

      expect(findAppendedText().exists()).toBe(true);
      expect(findAppendedText().find(GlSprintf).attributes('message')).toContain(
        mockData.modalPropsData.i18n.branchInFork,
      );
    });

    it('Shows the branch collaboration message', () => {
      createComponent(shallowMount, { pushCode: false, branchCollaboration: true });

      expect(findAppendedText().exists()).toBe(true);
      expect(findAppendedText().find(GlSprintf).attributes('message')).toContain(
        mockData.modalPropsData.i18n.existingBranch,
      );
    });
  });

  describe('Taking action on the form', () => {
    beforeEach(() => {
      createComponent(mount);
    });

    it('Action primary button dispatches submit action', () => {
      const submitSpy = jest.spyOn(findForm().element, 'submit');

      getByText(mockData.modalPropsData.i18n.actionPrimaryText).trigger('click');

      expect(submitSpy).toHaveBeenCalled();

      submitSpy.mockRestore();
    });

    it('Changes the start_branch input value', async () => {
      findBranchesDropdown().vm.$emit('selectBranch', '_changed_branch_value_');

      await wrapper.vm.$nextTick();

      expect(findStartBranch().attributes('value')).toBe('_changed_branch_value_');
    });

    it('Changes the target_project_id input value', async () => {
      createComponent(shallowMount, {}, {}, { isCherryPick: true });
      findProjectsDropdown().vm.$emit('selectProject', '_changed_project_value_');

      await wrapper.vm.$nextTick();

      expect(findTargetProject().attributes('value')).toBe('_changed_project_value_');
    });
  });
});
