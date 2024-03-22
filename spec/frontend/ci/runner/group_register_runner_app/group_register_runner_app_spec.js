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
import GoogleCloudRegistrationInstructions from '~/ci/runner/components/registration/google_cloud_registration_instructions.vue';
import GroupRegisterRunnerApp from '~/ci/runner/group_register_runner/group_register_runner_app.vue';
import RegistrationInstructions from '~/ci/runner/components/registration/registration_instructions.vue';
import PlatformsDrawer from '~/ci/runner/components/registration/platforms_drawer.vue';
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

  const findCloudRegistrationInstructions = () =>
    wrapper.findComponent(GoogleCloudRegistrationInstructions);
  const findRegistrationInstructions = () => wrapper.findComponent(RegistrationInstructions);
  const findPlatformsDrawer = () => wrapper.findComponent(PlatformsDrawer);
  const findBtn = () => wrapper.findComponent(GlButton);

  const createComponent = (googleCloudSupportFeatureFlag = false) => {
    trackingSpy = mockTracking(undefined, window.document, jest.spyOn);
    wrapper = shallowMountExtended(GroupRegisterRunnerApp, {
      propsData: {
        runnerId: mockRunnerId,
        runnersPath: mockRunnersPath,
        groupPath: mockGroupPath,
      },
      provide: {
        glFeatures: {
          googleCloudSupportFeatureFlag,
        },
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
        });
      });

      it('configures platform drawer', () => {
        expect(findPlatformsDrawer().props()).toEqual({
          open: false,
          platform: DEFAULT_PLATFORM,
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

  describe('When another platform has been selected', () => {
    beforeEach(() => {
      setWindowLocation(`?${PARAM_KEY_PLATFORM}=${WINDOWS_PLATFORM}`);

      createComponent();
    });

    it('shows registration instructions for the platform', () => {
      expect(findRegistrationInstructions().props('platform')).toBe(WINDOWS_PLATFORM);
    });
  });

  describe('When opening install instructions', () => {
    beforeEach(() => {
      createComponent();

      findRegistrationInstructions().vm.$emit('toggleDrawer');
    });

    it('opens platform drawer', () => {
      expect(findPlatformsDrawer().props('open')).toBe(true);
    });

    it('closes platform drawer', async () => {
      findRegistrationInstructions().vm.$emit('toggleDrawer');
      await nextTick();

      expect(findPlatformsDrawer().props('open')).toBe(false);
    });

    it('closes platform drawer from drawer', async () => {
      findPlatformsDrawer().vm.$emit('close');
      await nextTick();

      expect(findPlatformsDrawer().props('open')).toBe(false);
    });

    describe('when selecting a platform', () => {
      beforeEach(() => {
        findPlatformsDrawer().vm.$emit('selectPlatform', WINDOWS_PLATFORM);
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

  describe('Google cloud', () => {
    describe('flag enabled', () => {
      beforeEach(() => {
        setWindowLocation(`?${PARAM_KEY_PLATFORM}=${GOOGLE_CLOUD_PLATFORM}`);

        createComponent(true);
      });

      it('shows google cloud registration instructions', () => {
        expect(findCloudRegistrationInstructions().exists()).toBe(true);
        expect(findRegistrationInstructions().exists()).toBe(false);
      });
    });

    describe('flag disabled', () => {
      it('does not show google cloud registration instructions', () => {
        createComponent();

        expect(findCloudRegistrationInstructions().exists()).toBe(false);
        expect(findRegistrationInstructions().exists()).toBe(true);
      });
    });
  });
});
