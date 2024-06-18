import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { mockTracking } from 'helpers/tracking_helper';

import { InternalEvents } from '~/tracking';
import { updateHistory } from '~/lib/utils/url_utility';
import {
  PARAM_KEY_PLATFORM,
  DEFAULT_PLATFORM,
  WINDOWS_PLATFORM,
  GOOGLE_CLOUD_PLATFORM,
} from '~/ci/runner/constants';
import GroupRegisterRunnerApp from '~/ci/runner/group_register_runner/group_register_runner_app.vue';
import RegistrationInstructions from '~/ci/runner/components/registration/registration_instructions.vue';
import { runnerForRegistration } from '../mock_data';

const mockRunnerId = runnerForRegistration.data.runner.id;
const mockGroupPath = '/groups/group1';
const mockRunnersPath = '/groups/group1/-/runners';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  updateHistory: jest.fn(),
}));

describe('GroupRegisterRunnerApp', () => {
  let wrapper;
  let trackingSpy;

  const findRegistrationInstructions = () => wrapper.findComponent(RegistrationInstructions);
  const findBtn = () => wrapper.findComponent(GlButton);

  const createComponent = () => {
    trackingSpy = mockTracking(undefined, window.document, jest.spyOn);
    wrapper = shallowMountExtended(GroupRegisterRunnerApp, {
      propsData: {
        runnerId: mockRunnerId,
        runnersPath: mockRunnersPath,
        groupPath: mockGroupPath,
      },
    });
  };

  describe('When showing runner details', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('when runner token is available', () => {
      it('shows registration instructions', () => {
        expect(findRegistrationInstructions().props()).toEqual({
          platform: DEFAULT_PLATFORM,
          runnerId: mockRunnerId,
          groupPath: mockGroupPath,
          projectPath: null,
        });
      });

      it('shows runner list button', () => {
        expect(findBtn().attributes('href')).toBe(mockRunnersPath);
        expect(findBtn().attributes('data-event-tracking')).toBe(
          'click_view_runners_button_in_new_group_runner_form',
        );
        expect(findBtn().props('variant')).toBe('confirm');
      });
    });

    describe('when runner is registered', () => {
      beforeEach(() => {
        jest.spyOn(InternalEvents, 'trackEvent');
      });

      it('does not track event for platforms', () => {
        findRegistrationInstructions().vm.$emit('selectPlatform', WINDOWS_PLATFORM);
        findRegistrationInstructions().vm.$emit('runnerRegistered');

        expect(InternalEvents.trackEvent).toHaveBeenCalledTimes(0);
      });

      it('tracks event for google cloud platform', () => {
        findRegistrationInstructions().vm.$emit('selectPlatform', GOOGLE_CLOUD_PLATFORM);
        findRegistrationInstructions().vm.$emit('runnerRegistered');

        expect(InternalEvents.trackEvent).toHaveBeenCalledTimes(1);
        expect(InternalEvents.trackEvent).toHaveBeenCalledWith(
          'provision_group_runner_on_google_cloud',
          expect.any(Object),
          undefined,
        );
      });
    });

    describe('when runners list button is clicked', () => {
      beforeEach(async () => {
        InternalEvents.bindInternalEventDocument(findBtn().element);
        await findBtn().trigger('click');
        await nextTick();
      });

      it('tracks that view runners button has been clicked', () => {
        expect(trackingSpy).toHaveBeenCalledWith(
          undefined,
          'click_view_runners_button_in_new_group_runner_form',
          expect.any(Object),
        );
      });
    });
  });

  describe('When a platform is selected in the creation', () => {
    beforeEach(() => {
      setWindowLocation(`?${PARAM_KEY_PLATFORM}=${WINDOWS_PLATFORM}`);

      createComponent();
    });

    it('shows registration instructions for the platform', () => {
      expect(findRegistrationInstructions().props('platform')).toBe(WINDOWS_PLATFORM);
    });
  });

  describe('When a platform is selected in the instructions', () => {
    beforeEach(async () => {
      createComponent();

      findRegistrationInstructions().vm.$emit('selectPlatform', WINDOWS_PLATFORM);
      await nextTick();
    });

    it('updates the url', () => {
      expect(updateHistory).toHaveBeenCalledTimes(1);
      expect(updateHistory).toHaveBeenCalledWith({
        url: `${TEST_HOST}/?${PARAM_KEY_PLATFORM}=${WINDOWS_PLATFORM}`,
      });
    });

    it('updates the registration instructions', () => {
      expect(findRegistrationInstructions().props('platform')).toBe(WINDOWS_PLATFORM);
    });
  });
});
