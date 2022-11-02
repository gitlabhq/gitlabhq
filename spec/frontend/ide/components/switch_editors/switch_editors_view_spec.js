import { GlButton, GlEmptyState, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { createAlert } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { logError } from '~/lib/logger';
import { __ } from '~/locale';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import SwitchEditorsView, {
  MSG_ERROR_ALERT,
  MSG_CONFIRM,
  MSG_TITLE,
  MSG_LEARN_MORE,
  MSG_DESCRIPTION,
} from '~/ide/components/switch_editors/switch_editors_view.vue';
import eventHub from '~/ide/eventhub';
import { createStore } from '~/ide/stores';

jest.mock('~/flash');
jest.mock('~/lib/logger');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

const TEST_USER_PREFERENCES_PATH = '/test/user-pref/path';
const TEST_SWITCH_EDITOR_SVG_PATH = '/test/switch/editor/path.svg';
const TEST_HREF = '/test/new/web/ide/href';

describe('~/ide/components/switch_editors/switch_editors_view.vue', () => {
  useMockLocationHelper();

  let store;
  let wrapper;
  let confirmResolve;
  let requestSpy;
  let skipBeforeunloadSpy;
  let axiosMock;

  // region: finders ------------------
  const findButton = () => wrapper.findComponent(GlButton);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  // region: actions ------------------
  const triggerSwitchPreference = () => findButton().vm.$emit('click');
  const submitConfirm = async (val) => {
    confirmResolve(val);

    // why: We need to wait for promises for the immediate next lines to be executed
    await waitForPromises();
  };

  const createComponent = () => {
    wrapper = shallowMount(SwitchEditorsView, {
      store,
      stubs: {
        GlEmptyState,
      },
    });
  };

  // region: test setup ------------------
  beforeEach(() => {
    // Setup skip-beforeunload side-effect
    skipBeforeunloadSpy = jest.fn();
    eventHub.$on('skip-beforeunload', skipBeforeunloadSpy);

    // Setup request side-effect
    requestSpy = jest.fn().mockImplementation(() => new Promise(() => {}));
    axiosMock = new MockAdapter(axios);
    axiosMock.onPut(TEST_USER_PREFERENCES_PATH).reply(({ data }) => requestSpy(data));

    // Setup store
    store = createStore();
    store.state.userPreferencesPath = TEST_USER_PREFERENCES_PATH;
    store.state.switchEditorSvgPath = TEST_SWITCH_EDITOR_SVG_PATH;
    store.state.links = {
      newWebIDEHelpPagePath: TEST_HREF,
    };

    // Setup user confirm side-effect
    confirmAction.mockImplementation(
      () =>
        new Promise((resolve) => {
          confirmResolve = resolve;
        }),
    );
  });

  afterEach(() => {
    eventHub.$off('skip-beforeunload', skipBeforeunloadSpy);

    axiosMock.restore();
  });

  // region: tests ------------------
  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('render empty state', () => {
      expect(findEmptyState().props()).toMatchObject({
        svgPath: TEST_SWITCH_EDITOR_SVG_PATH,
        svgHeight: 150,
        title: MSG_TITLE,
      });
    });

    it('render link', () => {
      expect(wrapper.findComponent(GlLink).attributes('href')).toBe(TEST_HREF);
      expect(wrapper.findComponent(GlLink).text()).toBe(MSG_LEARN_MORE);
    });

    it('renders description', () => {
      expect(findEmptyState().text()).toContain(MSG_DESCRIPTION);
    });

    it('is not loading', () => {
      expect(findButton().props('loading')).toBe(false);
    });
  });

  describe('when user triggers switch preference', () => {
    beforeEach(() => {
      createComponent();

      triggerSwitchPreference();
    });

    it('creates a single confirm', () => {
      // Call again to ensure that we only show 1 confirm action
      triggerSwitchPreference();

      expect(confirmAction).toHaveBeenCalledTimes(1);
      expect(confirmAction).toHaveBeenCalledWith(MSG_CONFIRM, {
        primaryBtnText: __('Switch editors'),
        cancelBtnText: __('Cancel'),
      });
    });

    it('starts loading', () => {
      expect(findButton().props('loading')).toBe(true);
    });

    describe('when user cancels confirm', () => {
      beforeEach(async () => {
        await submitConfirm(false);
      });

      it('does not make request', () => {
        expect(requestSpy).not.toHaveBeenCalled();
      });

      it('can be triggered again', () => {
        triggerSwitchPreference();

        expect(confirmAction).toHaveBeenCalledTimes(2);
      });
    });

    describe('when user accepts confirm and response success', () => {
      beforeEach(async () => {
        requestSpy.mockReturnValue([200, {}]);
        await submitConfirm(true);
      });

      it('does not handle error', () => {
        expect(logError).not.toHaveBeenCalled();
        expect(createAlert).not.toHaveBeenCalled();
      });

      it('emits "skip-beforeunload" and reloads', () => {
        expect(skipBeforeunloadSpy).toHaveBeenCalledTimes(1);
        expect(window.location.reload).toHaveBeenCalledTimes(1);
      });

      it('calls request', () => {
        expect(requestSpy).toHaveBeenCalledTimes(1);
        expect(requestSpy).toHaveBeenCalledWith(
          JSON.stringify({ user: { use_legacy_web_ide: false } }),
        );
      });

      it('is not loading', () => {
        expect(findButton().props('loading')).toBe(false);
      });
    });

    describe('when user accepts confirm and response fails', () => {
      beforeEach(async () => {
        requestSpy.mockReturnValue([400, {}]);
        await submitConfirm(true);
      });

      it('handles error', () => {
        expect(logError).toHaveBeenCalledTimes(1);
        expect(logError).toHaveBeenCalledWith(
          'Error while updating user preferences',
          expect.any(Error),
        );

        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          message: MSG_ERROR_ALERT,
        });
      });

      it('does not reload', () => {
        expect(skipBeforeunloadSpy).not.toHaveBeenCalled();
        expect(window.location.reload).not.toHaveBeenCalled();
      });
    });
  });
});
