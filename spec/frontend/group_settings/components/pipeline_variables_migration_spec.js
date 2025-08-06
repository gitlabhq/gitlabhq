import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlButton, GlFormGroup, GlSprintf } from '@gitlab/ui';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PipelineVariablesMigration from '~/group_settings/pipeline_variables_default_role/pipeline_variables_migration.vue';
import safeDisablePipelineVariables from '~/group_settings/pipeline_variables_default_role/graphql/mutations/safe_disable_pipeline_variables.mutation.graphql';

Vue.use(VueApollo);
jest.mock('~/alert');

const $toast = {
  show: jest.fn(),
};

const TEST_FULL_PATH = 'group/project';

describe('PipelineVariablesMigration', () => {
  let wrapper;

  const defaultMutationResponse = jest.fn().mockResolvedValue({
    data: {
      safeDisablePipelineVariables: {
        success: true,
        errors: [],
      },
    },
  });

  const createComponent = async ({ mutationHandler = defaultMutationResponse } = {}) => {
    const apolloProvider = createMockApollo([[safeDisablePipelineVariables, mutationHandler]]);

    wrapper = shallowMount(PipelineVariablesMigration, {
      provide: {
        fullPath: TEST_FULL_PATH,
      },
      mocks: {
        $toast,
      },
      apolloProvider,
      stubs: { GlFormGroup, GlSprintf },
    });

    await waitForPromises();
  };

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findStartMigrationButton = () => wrapper.findComponent(GlButton);

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('component rendering', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('renders the form group with correct label', () => {
      expect(findFormGroup().exists()).toBe(true);
      expect(findFormGroup().attributes('label')).toBe(
        "Disable pipeline variables in projects that don't use them",
      );
    });

    it('renders the description text correctly', async () => {
      await createComponent();

      const text = findFormGroup().text();
      expect(text).toContain('In all projects that do not use pipeline variables');
      expect(text).toContain('Minimum role to use pipeline variables');
      expect(text).toContain('No one allowed');
      expect(text).toContain('Project owners can later choose a different setting');
    });

    it('renders the start migration button', () => {
      const button = findStartMigrationButton();

      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Start migration');
      expect(button.attributes('category')).toBe('secondary');
      expect(button.attributes('variant')).toBe('confirm');
    });

    it('renders button not in the loading state by default', () => {
      expect(findStartMigrationButton().props('loading')).toBe(false);
    });
  });

  describe('startMigration method', () => {
    describe('success case', () => {
      beforeEach(async () => {
        await createComponent();
      });

      it('calls the GraphQL mutation with correct variables', async () => {
        findStartMigrationButton().vm.$emit('click');
        await waitForPromises();

        expect(defaultMutationResponse).toHaveBeenCalledWith({
          fullPath: TEST_FULL_PATH,
        });
      });

      it('shows success toast when mutation succeeds', async () => {
        findStartMigrationButton().vm.$emit('click');
        await waitForPromises();

        expect($toast.show).toHaveBeenCalledWith(
          "Migration started. You'll receive an email notification after all projects have been migrated.",
        );
      });

      it('shows loading state on button during submission', async () => {
        findStartMigrationButton().vm.$emit('click');
        await nextTick();

        expect(findStartMigrationButton().props('loading')).toBe(true);

        await waitForPromises();
        expect(findStartMigrationButton().props('loading')).toBe(false);
      });
    });

    describe('GraphQL errors case', () => {
      beforeEach(async () => {
        const mutationHandler = jest.fn().mockResolvedValue({
          data: {
            safeDisablePipelineVariables: {
              success: false,
              errors: [{ message: 'Migration failed' }],
            },
          },
        });

        await createComponent({ mutationHandler });
        findStartMigrationButton().vm.$emit('click');
        await waitForPromises();
      });

      it('shows alert when mutation returns errors', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Migration failed',
        });
        expect($toast.show).not.toHaveBeenCalled();
      });

      it('resets loading state when mutation returns errors', () => {
        expect(findStartMigrationButton().props('loading')).toBe(false);
      });
    });

    describe('network errors case', () => {
      beforeEach(async () => {
        const mutationHandler = jest.fn().mockRejectedValue(new Error('Network error'));

        await createComponent({ mutationHandler });
        findStartMigrationButton().vm.$emit('click');
        await waitForPromises();
      });

      it('shows alert when mutation throws error', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'There was a problem starting the pipeline variables migration.',
        });
        expect($toast.show).not.toHaveBeenCalled();
      });

      it('resets loading state when mutation throws error', () => {
        expect(findStartMigrationButton().props('loading')).toBe(false);
      });
    });
  });
});
