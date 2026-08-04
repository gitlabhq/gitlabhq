import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlForm, GlFormGroup, GlLink, GlMultiStepFormTemplate, GlSprintf } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import RunnerCreateWizardOptionalFields from '~/ci/runner/components/runner_create_wizard_optional_fields.vue';
import { RUNNER_MAX_TIMEOUT_MIN_SECS } from '~/ci/runner/constants';
import runnerCreateMutation from '~/ci/runner/graphql/new/runner_create.mutation.graphql';
import { helpPagePath } from '~/helpers/help_page_helper';

Vue.use(VueApollo);

const mockRunnerId = 'gid://gitlab/Ci::Runner/7';
const mockRunnerCreateResult = {
  data: {
    runnerCreate: {
      errors: [],
      runner: {
        id: mockRunnerId,
        ephemeralRegisterUrl: 'http://test.host/admin/runners/7/register',
      },
    },
  },
};

describe('Create Runner Optional Fields', () => {
  let wrapper;

  const createComponent = ({ stubs, runnerCreateHandler } = {}) => {
    wrapper = shallowMountExtended(RunnerCreateWizardOptionalFields, {
      propsData: {
        currentStep: 2,
        stepsTotal: 3,
        tags: 'tag1, tag2',
        runUntagged: false,
        runnerType: 'INSTANCE_TYPE',
      },
      apolloProvider: createMockApollo([
        [
          runnerCreateMutation,
          runnerCreateHandler ?? jest.fn().mockResolvedValue(mockRunnerCreateResult),
        ],
      ]),
      stubs,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findForm = () => wrapper.findComponent(GlForm);
  const findGlMultiStepFormTemplate = () => wrapper.findComponent(GlMultiStepFormTemplate);
  const findNextButton = () => wrapper.findByTestId('next-button');
  const findBackButton = () => wrapper.findComponentByTestId('back-button');

  describe('form', () => {
    it('passes the correct props to GlMultiStepFormTemplate', () => {
      expect(findGlMultiStepFormTemplate().props()).toMatchObject({
        title: 'Optional configuration details',
        currentStep: 2,
        stepsTotal: 3,
      });
    });

    it('renders GlForm', () => {
      expect(findForm().exists()).toBe(true);
    });
  });

  it('renders the Next step button', () => {
    expect(findNextButton().text()).toBe('Next step');
    expect(findNextButton().attributes('type')).toBe('submit');
  });

  describe('when the runner is created', () => {
    it('emits `on-get-new-runner-id` with the new runner id, then `next`', async () => {
      findForm().vm.$emit('submit', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(wrapper.emitted('on-get-new-runner-id')).toEqual([[mockRunnerId]]);
      expect(wrapper.emitted('next')).toHaveLength(1);
    });
  });

  describe('when runner creation fails', () => {
    it('does not emit `on-get-new-runner-id` when the mutation returns errors', async () => {
      createComponent({
        runnerCreateHandler: jest.fn().mockResolvedValue({
          data: { runnerCreate: { errors: ['Runner could not be created'], runner: null } },
        }),
      });

      findForm().vm.$emit('submit', { preventDefault: jest.fn() });
      await waitForPromises();

      expect(wrapper.emitted('on-get-new-runner-id')).toBeUndefined();
    });
  });

  describe('back button', () => {
    it('renders the Go back button', () => {
      expect(findBackButton().text()).toBe('Go back');
    });

    it(`emits the "back" event when the back button is clicked`, () => {
      findBackButton().vm.$emit('click');
      expect(wrapper.emitted('back')).toHaveLength(1);
    });
  });

  describe('maximum job timeout field', () => {
    it('links to the job timeout documentation in a new tab', () => {
      createComponent({ stubs: { GlSprintf, GlFormGroup } });

      const link = wrapper.findComponent(GlLink);

      expect(link.attributes('href')).toBe(
        helpPagePath('ci/pipelines/settings', {
          anchor: 'set-a-limit-for-how-long-jobs-can-run',
        }),
      );
      expect(link.attributes('target')).toBe('_blank');
    });

    it('does not accept a value below the minimum the runner accepts', () => {
      createComponent();

      expect(wrapper.findByTestId('max-timeout-input').attributes('min')).toBe(
        `${RUNNER_MAX_TIMEOUT_MIN_SECS}`,
      );
    });
  });
});
