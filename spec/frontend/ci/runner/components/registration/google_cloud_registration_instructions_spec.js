import { GlAlert } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import GoogleCloudRegistrationInstructions from '~/ci/runner/components/registration/google_cloud_registration_instructions.vue';
import runnerForRegistrationQuery from '~/ci/runner/graphql/register/runner_for_registration.query.graphql';
import provisionGoogleCloudRunnerQueryProject from '~/ci/runner/graphql/register/provision_google_cloud_runner_project.query.graphql';
import provisionGoogleCloudRunnerQueryGroup from '~/ci/runner/graphql/register/provision_google_cloud_runner_group.query.graphql';
import {
  runnerForRegistration,
  mockAuthenticationToken,
  projectRunnerCloudProvisioningSteps,
  groupRunnerCloudProvisioningSteps,
} from '../../mock_data';

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

const mockProjectRunnerCloudSteps = {
  data: {
    project: {
      ...projectRunnerCloudProvisioningSteps,
    },
  },
};

const mockGroupRunnerCloudSteps = {
  data: {
    group: {
      ...groupRunnerCloudProvisioningSteps,
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
  const findModalTerrarformInstructions = () =>
    wrapper.findByTestId('terraform-script-instructions');
  const findModalTerrarformApplyInstructions = () =>
    wrapper.findByTestId('terraform-apply-instructions');
  const findModalBashInstructions = () => wrapper.findByTestId('bash-instructions');
  const findInstructionsButton = () => wrapper.findByTestId('show-instructions-button');
  const findAlert = () => wrapper.findComponent(GlAlert);

  const fillInGoogleForm = () => {
    findProjectIdInput().vm.$emit('input', 'dev-gcp-xxx-integrati-xxxxxxxx');
    findRegionInput().vm.$emit('input', 'us-central1');
    findZoneInput().vm.$emit('input', 'us-central1');

    findInstructionsButton().vm.$emit('click');

    return waitForPromises();
  };

  const runnerWithTokenResolver = jest.fn().mockResolvedValue(mockRunnerResponse);
  const runnerWithoutTokenResolver = jest.fn().mockResolvedValue(mockRunnerWithoutTokenResponse);
  const projectInstructionsResolver = jest.fn().mockResolvedValue(mockProjectRunnerCloudSteps);
  const groupInstructionsResolver = jest.fn().mockResolvedValue(mockGroupRunnerCloudSteps);

  const error = new Error('GraphQL error: One or more validations have failed');
  const errorResolver = jest.fn().mockRejectedValue(error);

  const defaultHandlers = [[runnerForRegistrationQuery, runnerWithTokenResolver]];
  const defaultProps = {
    runnerId: mockRunnerId,
    projectPath: 'test/project',
  };

  const createComponent = (
    mountFn = shallowMountExtended,
    handlers = defaultHandlers,
    props = defaultProps,
  ) => {
    wrapper = mountFn(GoogleCloudRegistrationInstructions, {
      apolloProvider: createMockApollo(handlers),
      propsData: {
        ...props,
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

  it('Shows an alert when the form has empty fields', async () => {
    createComponent();

    findInstructionsButton().vm.$emit('click');

    await waitForPromises();

    expect(findAlert().exists()).toBe(true);
    expect(findAlert().text()).toBe('To view the setup instructions, complete the previous form.');
  });

  it('Hides an alert when the form is valid', async () => {
    createComponent(mountExtended, [
      [provisionGoogleCloudRunnerQueryProject, projectInstructionsResolver],
    ]);

    findProjectIdInput().vm.$emit('input', 'dev-gcp-xxx-integrati-xxxxxxxx');
    findRegionInput().vm.$emit('input', 'us-central1');
    findZoneInput().vm.$emit('input', 'us-central1');
    findMachineTypeInput().vm.$emit('input', 'n2d-standard-2');

    findInstructionsButton().vm.$emit('click');

    await waitForPromises();

    expect(findAlert().exists()).toBe(false);
  });

  it('Shows a modal with the correspondent scripts for a project', async () => {
    createComponent(shallowMountExtended, [
      [provisionGoogleCloudRunnerQueryProject, projectInstructionsResolver],
    ]);

    await fillInGoogleForm();

    expect(projectInstructionsResolver).toHaveBeenCalled();
    expect(groupInstructionsResolver).not.toHaveBeenCalled();

    expect(findModalBashInstructions().text()).not.toBeNull();
    expect(findModalTerrarformInstructions().text()).not.toBeNull();
    expect(findModalTerrarformApplyInstructions().text).not.toBeNull();
  });

  it('Shows a modal with the correspondent scripts for a group', async () => {
    createComponent(
      shallowMountExtended,
      [[provisionGoogleCloudRunnerQueryGroup, groupInstructionsResolver]],
      { runnerId: mockRunnerId, groupPath: 'groups/test' },
    );

    await fillInGoogleForm();

    expect(groupInstructionsResolver).toHaveBeenCalled();
    expect(projectInstructionsResolver).not.toHaveBeenCalled();

    expect(findModalBashInstructions().text()).not.toBeNull();
    expect(findModalTerrarformInstructions().text()).not.toBeNull();
    expect(findModalTerrarformApplyInstructions().text).not.toBeNull();
  });

  it('Does not display a modal with text when validation errors occur', async () => {
    createComponent(mountExtended, [[provisionGoogleCloudRunnerQueryProject, errorResolver]]);

    findProjectIdInput().vm.$emit('input', 'dev-gcp-xxx-integrati-xxxxxxxx');
    findRegionInput().vm.$emit('input', 'us-central1xxx');
    findZoneInput().vm.$emit('input', 'us-central181263');

    await waitForPromises();

    expect(errorResolver).toHaveBeenCalled();

    expect(findAlert().text()).toContain(
      'To view the setup instructions, make sure all form fields are completed and correct.',
    );

    expect(findModalBashInstructions().exists()).toBe(false);
    expect(findModalTerrarformInstructions().exists()).toBe(false);
    expect(findModalTerrarformApplyInstructions().exists()).toBe(false);
  });
});
