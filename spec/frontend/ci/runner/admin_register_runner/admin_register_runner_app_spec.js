import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton } from '@gitlab/ui';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';

import { updateHistory } from '~/lib/utils/url_utility';
import runnerForRegistrationQuery from '~/ci/runner/graphql/register/runner_for_registration.query.graphql';
import { PARAM_KEY_PLATFORM, DEFAULT_PLATFORM, WINDOWS_PLATFORM } from '~/ci/runner/constants';
import AdminRegisterRunnerApp from '~/ci/runner/admin_register_runner/admin_register_runner_app.vue';
import RegistrationInstructions from '~/ci/runner/components/registration/registration_instructions.vue';
import PlatformsDrawer from '~/ci/runner/components/registration/platforms_drawer.vue';
import { runnerForRegistration } from '../mock_data';

const mockRunner = runnerForRegistration.data.runner;
const mockRunnerId = `${getIdFromGraphQLId(mockRunner.id)}`;
const mockRunnersPath = '/admin/runners';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  updateHistory: jest.fn(),
}));

describe('AdminRegisterRunnerApp', () => {
  let wrapper;
  let mockRunnerQuery;

  const findRegistrationInstructions = () => wrapper.findComponent(RegistrationInstructions);
  const findPlatformsDrawer = () => wrapper.findComponent(PlatformsDrawer);
  const findBtn = () => wrapper.findComponent(GlButton);

  const createComponent = () => {
    wrapper = shallowMountExtended(AdminRegisterRunnerApp, {
      apolloProvider: createMockApollo([[runnerForRegistrationQuery, mockRunnerQuery]]),
      propsData: {
        runnerId: mockRunnerId,
        runnersPath: mockRunnersPath,
      },
    });
  };

  beforeEach(() => {
    mockRunnerQuery = jest.fn().mockResolvedValue({
      data: {
        runner: mockRunner,
      },
    });
  });

  describe('When showing runner details', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('loads runner', () => {
      expect(mockRunnerQuery).toHaveBeenCalledWith({ id: mockRunner.id });
    });

    it('shows registration instructions', () => {
      expect(findRegistrationInstructions().props()).toEqual({
        loading: false,
        platform: DEFAULT_PLATFORM,
        runner: mockRunner,
      });
    });

    it('configures platform drawer', () => {
      expect(findPlatformsDrawer().props()).toEqual({
        open: false,
        platform: DEFAULT_PLATFORM,
      });
    });

    it('shows runner list button', () => {
      expect(findBtn().attributes('href')).toEqual(mockRunnersPath);
      expect(findBtn().props('variant')).toEqual('confirm');
    });
  });

  describe('When another platform has been selected', () => {
    beforeEach(async () => {
      setWindowLocation(`?${PARAM_KEY_PLATFORM}=${WINDOWS_PLATFORM}`);

      createComponent();
      await waitForPromises();
    });

    it('shows registration instructions for the platform', () => {
      expect(findRegistrationInstructions().props('platform')).toEqual(WINDOWS_PLATFORM);
    });
  });

  describe('When opening install instructions', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();

      findRegistrationInstructions().vm.$emit('toggleDrawer');
      await nextTick();
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
      beforeEach(async () => {
        findPlatformsDrawer().vm.$emit('selectPlatform', WINDOWS_PLATFORM);
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

  describe('When runner is loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows registration instructions', () => {
      expect(findRegistrationInstructions().props()).toEqual({
        loading: true,
        runner: null,
        platform: DEFAULT_PLATFORM,
      });
    });
  });
});
