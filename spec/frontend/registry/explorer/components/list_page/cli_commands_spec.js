import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import { GlDropdown, GlFormGroup, GlFormInputGroup } from '@gitlab/ui';
import Tracking from '~/tracking';
import * as getters from '~/registry/explorer/stores/getters';
import QuickstartDropdown from '~/registry/explorer/components/list_page/cli_commands.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

import {
  QUICK_START,
  LOGIN_COMMAND_LABEL,
  COPY_LOGIN_TITLE,
  BUILD_COMMAND_LABEL,
  COPY_BUILD_TITLE,
  PUSH_COMMAND_LABEL,
  COPY_PUSH_TITLE,
} from '~/registry/explorer//constants';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('cli_commands', () => {
  let wrapper;
  let store;

  const findDropdownButton = () => wrapper.find(GlDropdown);
  const findFormGroups = () => wrapper.findAll(GlFormGroup);

  const mountComponent = () => {
    store = new Vuex.Store({
      state: {
        config: {
          repositoryUrl: 'foo',
          registryHostUrlWithPort: 'bar',
        },
      },
      getters,
    });
    wrapper = mount(QuickstartDropdown, {
      localVue,
      store,
    });
  };

  beforeEach(() => {
    jest.spyOn(Tracking, 'event');
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    store = null;
  });

  it('shows the correct text on the button', () => {
    expect(findDropdownButton().text()).toContain(QUICK_START);
  });

  it('clicking on the dropdown emit a tracking event', () => {
    findDropdownButton().vm.$emit('shown');
    expect(Tracking.event).toHaveBeenCalledWith(
      undefined,
      'click_dropdown',
      expect.objectContaining({ label: 'quickstart_dropdown' }),
    );
  });

  describe.each`
    index | id                    | labelText              | titleText           | getter                  | trackedEvent
    ${0}  | ${'docker-login-btn'} | ${LOGIN_COMMAND_LABEL} | ${COPY_LOGIN_TITLE} | ${'dockerLoginCommand'} | ${'click_copy_login'}
    ${1}  | ${'docker-build-btn'} | ${BUILD_COMMAND_LABEL} | ${COPY_BUILD_TITLE} | ${'dockerBuildCommand'} | ${'click_copy_build'}
    ${2}  | ${'docker-push-btn'}  | ${PUSH_COMMAND_LABEL}  | ${COPY_PUSH_TITLE}  | ${'dockerPushCommand'}  | ${'click_copy_push'}
  `('form group at $index', ({ index, id, labelText, titleText, getter, trackedEvent }) => {
    let formGroup;

    const findFormInputGroup = parent => parent.find(GlFormInputGroup);
    const findClipboardButton = parent => parent.find(ClipboardButton);

    beforeEach(() => {
      formGroup = findFormGroups().at(index);
    });

    it('exists', () => {
      expect(formGroup.exists()).toBe(true);
    });

    it(`has a label ${labelText}`, () => {
      expect(formGroup.text()).toBe(labelText);
    });

    it(`contains a form input group with ${id} id and with value equal to ${getter} getter`, () => {
      const formInputGroup = findFormInputGroup(formGroup);
      expect(formInputGroup.exists()).toBe(true);
      expect(formInputGroup.attributes('id')).toBe(id);
      expect(formInputGroup.props('value')).toBe(store.getters[getter]);
    });

    it(`contains a clipboard button with title of ${titleText} and text equal to ${getter} getter`, () => {
      const clipBoardButton = findClipboardButton(formGroup);
      expect(clipBoardButton.exists()).toBe(true);
      expect(clipBoardButton.props('title')).toBe(titleText);
      expect(clipBoardButton.props('text')).toBe(store.getters[getter]);
    });

    it('clipboard button tracks click event', () => {
      const clipBoardButton = findClipboardButton(formGroup);
      clipBoardButton.trigger('click');
      /* This expect to be called with first argument undefined so that
       * the function internally can default to document.body.dataset.page
       * https://docs.gitlab.com/ee/telemetry/frontend.html#tracking-within-vue-components
       */
      expect(Tracking.event).toHaveBeenCalledWith(
        undefined,
        trackedEvent,
        expect.objectContaining({ label: 'quickstart_dropdown' }),
      );
    });
  });
});
