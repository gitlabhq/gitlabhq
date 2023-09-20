import { GlModal, GlForm, GlFormCheckbox, GlSprintf } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import { createWrapper } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import api from '~/api';
import axios from '~/lib/utils/axios_utils';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import BranchesDropdown from '~/projects/commit/components/branches_dropdown.vue';
import CommitFormModal from '~/projects/commit/components/form_modal.vue';
import ProjectsDropdown from '~/projects/commit/components/projects_dropdown.vue';
import eventHub from '~/projects/commit/event_hub';
import createStore from '~/projects/commit/store';
import mockData from '../mock_data';

jest.mock('~/api');

describe('CommitFormModal', () => {
  let wrapper;
  let store;
  let axiosMock;

  const createComponent = ({
    method = shallowMountExtended,
    state = {},
    provide = {},
    propsData = {},
  } = {}) => {
    store = createStore({ ...mockData.mockModal, ...state });
    wrapper = method(CommitFormModal, {
      provide: {
        ...provide,
      },
      propsData: { ...mockData.modalPropsData, ...propsData },
      store,
      attrs: {
        static: true,
        visible: true,
      },
    });
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
    axiosMock.restore();
  });

  describe('Basic interactions', () => {
    it('Listens for opening of modal on mount', () => {
      jest.spyOn(eventHub, '$on');

      createComponent();

      expect(eventHub.$on).toHaveBeenCalledWith(mockData.modalPropsData.openModal, wrapper.vm.show);
    });

    it('Shows modal', () => {
      createComponent();
      const rootWrapper = createWrapper(wrapper.vm.$root);

      eventHub.$emit(mockData.modalPropsData.openModal);

      expect(rootWrapper.emitted(BV_SHOW_MODAL)[0]).toContain(mockData.modalPropsData.modalId);
    });

    it('Clears the modal state once modal is hidden', () => {
      createComponent();
      jest.spyOn(store, 'dispatch').mockImplementation();
      findCheckBox().vm.$emit('input', false);

      findModal().vm.$emit('hidden');

      expect(store.dispatch).toHaveBeenCalledWith('clearModal');
      expect(store.dispatch).toHaveBeenCalledWith('setSelectedBranch', '');
      expect(findCheckBox().attributes('checked')).toBe('true');
    });

    it('Shows the checkbox for new merge request', () => {
      createComponent();

      expect(findCheckBox().exists()).toBe(true);
    });

    it('Shows the prepended text', () => {
      createComponent({ provide: { prependedText: '_prepended_text_' } });

      expect(findPrependedText().exists()).toBe(true);
      expect(findPrependedText().findComponent(GlSprintf).attributes('message')).toBe(
        '_prepended_text_',
      );
    });

    it('Does not show prepended text', () => {
      createComponent();

      expect(findPrependedText().exists()).toBe(false);
    });

    it('Does not show extra message text', () => {
      createComponent();

      expect(findModal().find('[data-testid="appended-text"]').exists()).toBe(false);
    });

    it('Does not show the checkbox for new merge request', () => {
      createComponent({ state: { pushCode: false } });

      expect(findCheckBox().exists()).toBe(false);
    });

    it('Shows the branch in fork message', () => {
      createComponent({ state: { pushCode: false } });

      expect(findAppendedText().exists()).toBe(true);
      expect(findAppendedText().findComponent(GlSprintf).attributes('message')).toContain(
        mockData.modalPropsData.i18n.branchInFork,
      );
    });

    it('Shows the branch collaboration message', () => {
      createComponent({ state: { pushCode: false, branchCollaboration: true } });

      expect(findAppendedText().exists()).toBe(true);
      expect(findAppendedText().findComponent(GlSprintf).attributes('message')).toContain(
        mockData.modalPropsData.i18n.existingBranch,
      );
    });
  });

  describe('Taking action on the form', () => {
    beforeEach(() => {
      createComponent({ method: mountExtended });
    });

    it('Action primary button dispatches submit action', () => {
      getByText(mockData.modalPropsData.i18n.actionPrimaryText).trigger('click');
      const formSubmitSpy = jest.spyOn(findForm().element, 'submit');

      expect(formSubmitSpy).toHaveBeenCalled();
    });

    it('Changes the start_branch input value', async () => {
      findBranchesDropdown().vm.$emit('input', '_changed_branch_value_');

      await nextTick();

      expect(findStartBranch().attributes('value')).toBe('_changed_branch_value_');
    });

    it('Changes the target_project_id input value', async () => {
      createComponent({ propsData: { isCherryPick: true } });
      findProjectsDropdown().vm.$emit('input', '_changed_project_value_');

      await nextTick();

      expect(findTargetProject().attributes('value')).toBe('_changed_project_value_');
    });
  });

  it('action primary button triggers Redis HLL tracking api call', async () => {
    createComponent({ method: mountExtended, propsData: { primaryActionEventName: 'test_event' } });
    await nextTick();

    getByText(mockData.modalPropsData.i18n.actionPrimaryText).trigger('click');

    expect(api.trackRedisHllUserEvent).toHaveBeenCalledWith('test_event');
  });
});
