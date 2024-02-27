import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import GoogleCloudRegistrationInstructions from '~/ci/runner/components/registration/google_cloud_registration_instructions.vue';
import runnerForRegistrationQuery from '~/ci/runner/graphql/register/runner_for_registration.query.graphql';
import { runnerForRegistration, mockAuthenticationToken } from '../../mock_data';

Vue.use(VueApollo);

const mockRunnerResponse = {
  data: {
    runner: {
      ...runnerForRegistration.data.runner,
      ephemeralAuthenticationToken: mockAuthenticationToken,
    },
  },
};
const mockRunnerWithoutTokenResponse = {
  data: {
    runner: {
      ...runnerForRegistration.data.runner,
      ephemeralAuthenticationToken: null,
    },
  },
};

const mockRunnerId = `${getIdFromGraphQLId(runnerForRegistration.data.runner.id)}`;

describe('GoogleCloudRegistrationInstructions', () => {
  let wrapper;

  const findProjectIdInput = () => wrapper.findByTestId('project-id-input');
  const findRegionInput = () => wrapper.findByTestId('region-input');
  const findZoneInput = () => wrapper.findByTestId('zone-input');
  const findMachineTypeInput = () => wrapper.findByTestId('machine-type-input');
  const findProjectIdLink = () => wrapper.findByTestId('project-id-link');
  const findZoneLink = () => wrapper.findByTestId('zone-link');
  const findMachineTypeLink = () => wrapper.findByTestId('machine-types-link');
  const findToken = () => wrapper.findByTestId('runner-token');
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);

  const runnerWithTokenResolver = jest.fn().mockResolvedValue(mockRunnerResponse);
  const runnerWithoutTokenResolver = jest.fn().mockResolvedValue(mockRunnerWithoutTokenResponse);

  const defaultHandlers = [[runnerForRegistrationQuery, runnerWithTokenResolver]];

  const createComponent = (mountFn = shallowMountExtended, handlers = defaultHandlers) => {
    wrapper = mountFn(GoogleCloudRegistrationInstructions, {
      apolloProvider: createMockApollo(handlers),
      propsData: {
        runnerId: mockRunnerId,
      },
    });
  };

  it('displays form inputs', () => {
    createComponent();

    expect(findProjectIdInput().exists()).toBe(true);
    expect(findRegionInput().exists()).toBe(true);
    expect(findZoneInput().exists()).toBe(true);
    expect(findMachineTypeInput().exists()).toBe(true);
  });

  it('machine type input has a default value', () => {
    createComponent();

    expect(findMachineTypeInput().attributes('value')).toBe('n2d-standard-2');
  });

  it('contains external docs links', () => {
    createComponent(mountExtended);

    expect(findProjectIdLink().attributes('href')).toBe(
      'https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects',
    );
    expect(findZoneLink().attributes('href')).toBe(
      'https://console.cloud.google.com/compute/zones?pli=1',
    );
    expect(findMachineTypeLink().attributes('href')).toBe(
      'https://cloud.google.com/compute/docs/general-purpose-machines#n2d_machine_types',
    );
  });

  it('calls runner for registration query', () => {
    createComponent();

    expect(runnerWithTokenResolver).toHaveBeenCalled();
  });

  it('displays runner token', async () => {
    createComponent(mountExtended);

    await waitForPromises();

    expect(findToken().exists()).toBe(true);
    expect(findToken().text()).toBe(mockAuthenticationToken);
    expect(findClipboardButton().exists()).toBe(true);
    expect(findClipboardButton().props('text')).toBe(mockAuthenticationToken);
  });

  it('does not display runner token', async () => {
    createComponent(mountExtended, [[runnerForRegistrationQuery, runnerWithoutTokenResolver]]);

    await waitForPromises();

    expect(findToken().exists()).toBe(false);
    expect(findClipboardButton().exists()).toBe(false);
  });
});
