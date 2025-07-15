import { GlAlert } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import GoogleCloudRegistrationInstructions from '~/ci/runner/components/registration/google_cloud_registration_instructions.vue';
import GoogleCloudRegistrationInstructionsModal from '~/ci/runner/components/registration/google_cloud_registration_instructions_modal.vue';
import provisionGoogleCloudRunnerQueryProject from '~/ci/runner/graphql/register/provision_google_cloud_runner_project.query.graphql';
import provisionGoogleCloudRunnerQueryGroup from '~/ci/runner/graphql/register/provision_google_cloud_runner_group.query.graphql';
import {
  mockAuthenticationToken,
  projectRunnerCloudProvisioningSteps,
  groupRunnerCloudProvisioningSteps,
} from '../../mock_data';

Vue.use(VueApollo);

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

const mockGroupPath = 'test/group';
const mockProjectPath = 'test/project';

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
  const findTokenMessage = () => wrapper.findByTestId('runner-token-message');
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findInstructionsButton = () => wrapper.findByTestId('show-instructions-button');

  const findGoogleCloudInstructionsModal = () =>
    wrapper.findComponent(GoogleCloudRegistrationInstructionsModal);

  const fillInTextField = (formGroup, value) => {
    const input = formGroup.find('input');
    input.element.value = value;
    return input.trigger('change');
  };

  const fillInGoogleForm = () => {
    fillInTextField(findProjectIdInput(), 'dev-gcp-xxx-integrati-xxxxxxxx');
    fillInTextField(findRegionInput(), 'us-central1');
    fillInTextField(findZoneInput(), 'us-central1-a');
    fillInTextField(findMachineTypeInput(), 'n2d-standard-4');

    findInstructionsButton().vm.$emit('click');

    return waitForPromises();
  };

  const projectInstructionsResolver = jest.fn().mockResolvedValue(mockProjectRunnerCloudSteps);
  const groupInstructionsResolver = jest.fn().mockResolvedValue(mockGroupRunnerCloudSteps);
  const errorResolver = jest
    .fn()
    .mockRejectedValue(new Error('GraphQL error: One or more validations have failed'));

  const createComponent = ({ props = {}, handlers = [] } = {}) => {
    wrapper = mountExtended(GoogleCloudRegistrationInstructions, {
      apolloProvider: createMockApollo(handlers),
      propsData: {
        token: mockAuthenticationToken,
        ...props,
      },
      attachTo: document.body,
    });
  };

  it('displays runner token', async () => {
    createComponent();

    await waitForPromises();

    expect(findToken().exists()).toBe(true);
    expect(findToken().text()).toBe(mockAuthenticationToken);
    expect(findClipboardButton().exists()).toBe(true);
    expect(findClipboardButton().props('text')).toBe(mockAuthenticationToken);
  });

  it('does not display runner token', async () => {
    createComponent({
      props: { token: null },
    });

    await waitForPromises();

    expect(findToken().exists()).toBe(false);
    expect(findClipboardButton().exists()).toBe(false);
  });

  it('contains external docs links', () => {
    createComponent();

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

  it('displays form inputs', () => {
    createComponent();

    expect(findProjectIdInput().exists()).toBe(true);
    expect(findRegionInput().exists()).toBe(true);
    expect(findZoneInput().exists()).toBe(true);
    expect(findMachineTypeInput().exists()).toBe(true);
  });

  it('machine type input has a default value', () => {
    createComponent();

    expect(findMachineTypeInput().find('input').element.value).toEqual('n2d-standard-2');
  });

  it('Shows an alert when the form has empty fields', async () => {
    createComponent();

    findInstructionsButton().vm.$emit('click');

    await waitForPromises();

    expect(findAlert().exists()).toBe(true);

    expect(findAlert().text()).toContain(
      'To view the setup instructions, complete the previous form.',
    );
  });

  describe('when fetching instructions for a project runner', () => {
    beforeEach(async () => {
      createComponent({
        props: { projectPath: mockProjectPath },
        handlers: [[provisionGoogleCloudRunnerQueryProject, projectInstructionsResolver]],
      });

      await fillInGoogleForm();
    });

    it('Hides an alert when the form is valid', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('Shows a modal with the correspondent scripts for a project', () => {
      expect(projectInstructionsResolver).toHaveBeenCalled();
      expect(groupInstructionsResolver).not.toHaveBeenCalled();

      expect(findGoogleCloudInstructionsModal().props()).toEqual({
        visible: true,
        applyTerraformScript: 'mock project apply terraform script',
        setupBashScript: 'mock project setup bash script',
        setupTerraformFile: 'mock project setup terraform file',
      });
    });
  });

  describe('when fetching instructions for a group runner', () => {
    beforeEach(async () => {
      createComponent({
        props: { groupPath: mockGroupPath },
        handlers: [[provisionGoogleCloudRunnerQueryGroup, groupInstructionsResolver]],
      });

      await fillInGoogleForm();
    });

    it('Hides an alert when the form is valid', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('Shows a modal with the correspondent scripts for a group', () => {
      expect(groupInstructionsResolver).toHaveBeenCalled();
      expect(projectInstructionsResolver).not.toHaveBeenCalled();

      expect(findGoogleCloudInstructionsModal().props()).toEqual({
        visible: true,
        applyTerraformScript: 'mock group apply terraform script',
        setupBashScript: 'mock group setup bash script',
        setupTerraformFile: 'mock group setup terraform file',
      });
    });
  });

  describe('when fetching instructions fails', () => {
    beforeEach(async () => {
      createComponent({
        props: { projectPath: mockProjectPath },
        handlers: [[provisionGoogleCloudRunnerQueryProject, errorResolver]],
      });

      await fillInGoogleForm();
    });

    it('Does not display a modal with text when validation errors occur', () => {
      expect(errorResolver).toHaveBeenCalled();

      expect(findAlert().text()).toContain(
        'To view the setup instructions, make sure all form fields are completed and correct.',
      );

      expect(findGoogleCloudInstructionsModal().props()).toEqual({
        visible: true,
        applyTerraformScript: null,
        setupBashScript: null,
        setupTerraformFile: null,
      });
    });
  });

  describe('Field validation', () => {
    const expectValidation = (fieldGroup, { ariaInvalid, feedback }) => {
      expect(fieldGroup.attributes('aria-invalid')).toBe(ariaInvalid);
      expect(fieldGroup.find('input').attributes('aria-invalid')).toBe(ariaInvalid);
      expect(fieldGroup.text()).toContain(feedback);
    };

    beforeEach(() => {
      createComponent();
    });

    describe('cloud project id validates', () => {
      it.each`
        case                                 | input                                | ariaInvalid  | feedback
        ${'correct'}                         | ${'correct-project-name'}            | ${undefined} | ${''}
        ${'correct'}                         | ${'correct-project-name-1'}          | ${undefined} | ${''}
        ${'correct'}                         | ${'project'}                         | ${undefined} | ${''}
        ${'invalid (too short)'}             | ${'short'}                           | ${'true'}    | ${'Project ID must have'}
        ${'invalid (starts with a number)'}  | ${'1number'}                         | ${'true'}    | ${'Project ID must have'}
        ${'invalid (starts with uppercase)'} | ${'Project'}                         | ${'true'}    | ${'Project ID must have'}
        ${'invalid (contains uppercase)'}    | ${'pRoject'}                         | ${'true'}    | ${'Project ID must have'}
        ${'invalid (contains symbol)'}       | ${'pro!ect'}                         | ${'true'}    | ${'Project ID must have'}
        ${'invalid (too long)'}              | ${'a-project-name-that-is-too-long'} | ${'true'}    | ${'Project ID must have'}
        ${'invalid (ends with hyphen)'}      | ${'a-project-'}                      | ${'true'}    | ${'Project ID must have'}
        ${'invalid (missing)'}               | ${''}                                | ${'true'}    | ${'Project ID is required'}
      `('"$input" as $case', async ({ input, ariaInvalid, feedback }) => {
        await fillInTextField(findProjectIdInput(), input);

        expectValidation(findProjectIdInput(), { ariaInvalid, feedback });
      });
    });

    describe('region validates', () => {
      it.each`
        case                           | input                | ariaInvalid  | feedback
        ${'correct'}                   | ${'us-central1'}     | ${undefined} | ${''}
        ${'correct'}                   | ${'europe-west8'}    | ${undefined} | ${''}
        ${'correct'}                   | ${'moon-up99'}       | ${undefined} | ${''}
        ${'invalid (is zone)'}         | ${'us-central1-a'}   | ${'true'}    | ${'Region must have'}
        ${'invalid (one part)'}        | ${'one2'}            | ${'true'}    | ${'Region must have'}
        ${'invalid (three parts)'}     | ${'one-two-three4'}  | ${'true'}    | ${'Region must have'}
        ${'invalid (contains symbol)'} | ${'one!-two-three4'} | ${'true'}    | ${'Region must have'}
        ${'invalid (typo)'}            | ${'one--two3'}       | ${'true'}    | ${'Region must have'}
        ${'invalid (too short)'}       | ${'wrong'}           | ${'true'}    | ${'Region must have'}
        ${'invalid (missing)'}         | ${''}                | ${'true'}    | ${'Region is required'}
      `('"$input" as $case', async ({ input, ariaInvalid, feedback }) => {
        await fillInTextField(findRegionInput(), input);

        expectValidation(findRegionInput(), { ariaInvalid, feedback });
      });
    });

    describe('zone validates', () => {
      it.each`
        case                           | input                  | ariaInvalid  | feedback
        ${'correct'}                   | ${'us-central1-a'}     | ${undefined} | ${''}
        ${'correct'}                   | ${'europe-west8-b'}    | ${undefined} | ${''}
        ${'correct'}                   | ${'moon-up99-z'}       | ${undefined} | ${''}
        ${'invalid (one part)'}        | ${'one2-a'}            | ${'true'}    | ${'Zone must have'}
        ${'invalid (three parts)'}     | ${'one-two-three4-b'}  | ${'true'}    | ${'Zone must have'}
        ${'invalid (contains symbol)'} | ${'one!-two-three4-c'} | ${'true'}    | ${'Zone must have'}
        ${'invalid (typo)'}            | ${'one--two3-d'}       | ${'true'}    | ${'Zone must have'}
        ${'invalid (too short)'}       | ${'wrong'}             | ${'true'}    | ${'Zone must have'}
        ${'invalid (missing)'}         | ${''}                  | ${'true'}    | ${'Zone is required'}
      `('"$input" as $case', async ({ input, ariaInvalid, feedback }) => {
        await fillInTextField(findZoneInput(), input);

        expectValidation(findZoneInput(), { ariaInvalid, feedback });
      });
    });

    describe('machine type validates', () => {
      it.each`
        case                            | input                   | ariaInvalid  | feedback
        ${'correct'}                    | ${'n2-standard-2'}      | ${undefined} | ${''}
        ${'correct'}                    | ${'t2d-standard-1'}     | ${undefined} | ${''}
        ${'correct'}                    | ${'t2a-standard-48'}    | ${undefined} | ${''}
        ${'correct'}                    | ${'t2d-standard-1'}     | ${undefined} | ${''}
        ${'correct'}                    | ${'c3-standard-4-lssd'} | ${undefined} | ${''}
        ${'correct'}                    | ${'f1-micro'}           | ${undefined} | ${''}
        ${'correct'}                    | ${'f1'}                 | ${undefined} | ${''}
        ${'invalid (uppercase letter)'} | ${'N2-standard-2'}      | ${'true'}    | ${'Machine type must have'}
        ${'invalid (number)'}           | ${'22-standard-2'}      | ${'true'}    | ${'Machine type must have'}
        ${'invalid (ends in dash)'}     | ${'22-standard-2-'}     | ${'true'}    | ${'Machine type must have'}
        ${'invalid (contains space)'}   | ${'n2-standard-2 '}     | ${'true'}    | ${'Machine type must have'}
        ${'invalid (missing)'}          | ${''}                   | ${'true'}    | ${'Machine type is required'}
      `('"$input" as $case', async ({ input, ariaInvalid, feedback }) => {
        await fillInTextField(findMachineTypeInput(), input);

        expectValidation(findMachineTypeInput(), { ariaInvalid, feedback });
      });
    });
  });

  describe('when isWidget is true', () => {
    beforeEach(() => {
      createComponent({
        props: { isWidget: true },
      });
    });

    it('does not display h2 headings', () => {
      expect(wrapper.find('h2').exists()).toBe(false);
    });

    it('does not display token message', () => {
      expect(findTokenMessage().exists()).toBe(false);
    });
  });
});
