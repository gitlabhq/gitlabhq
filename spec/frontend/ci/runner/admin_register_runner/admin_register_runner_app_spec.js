import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton } from '@gitlab/ui';

import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';

import { s__ } from '~/locale';
import runnerForRegistrationQuery from '~/ci/runner/graphql/register/runner_for_registration.query.graphql';
import { PARAM_KEY_PLATFORM, DEFAULT_PLATFORM, WINDOWS_PLATFORM } from '~/ci/runner/constants';
import AdminRegisterRunnerApp from '~/ci/runner/admin_register_runner/admin_register_runner_app.vue';
import RegistrationInstructions from '~/ci/runner/components/registration/registration_instructions.vue';
import { runnerForRegistration } from '../mock_data';

const mockRunner = runnerForRegistration.data.runner;
const mockRunnerId = `${getIdFromGraphQLId(mockRunner.id)}`;
const mockRunnersPath = '/admin/runners';
const MOCK_TOKEN = 'MOCK_TOKEN';

Vue.use(VueApollo);

describe('AdminRegisterRunnerApp', () => {
  let wrapper;
  let mockRunnerQuery;

  const findRegistrationInstructions = () => wrapper.findComponent(RegistrationInstructions);
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
        runner: { ...mockRunner, ephemeralAuthenticationToken: MOCK_TOKEN },
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

    it('shows heading', () => {
      expect(wrapper.find('h1').text()).toContain(mockRunner.description);
    });

    it('shows registration instructions', () => {
      expect(findRegistrationInstructions().props()).toEqual({
        loading: false,
        platform: DEFAULT_PLATFORM,
        token: MOCK_TOKEN,
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

  describe('When runner is loading', () => {
    beforeEach(async () => {
      createComponent();
    });

    it('shows heading', () => {
      expect(wrapper.find('h1').text()).toBe(s__('Runners|Register runner'));
    });

    it('shows registration instructions', () => {
      expect(findRegistrationInstructions().props()).toEqual({
        loading: true,
        token: null,
        platform: DEFAULT_PLATFORM,
      });
    });
  });
});
