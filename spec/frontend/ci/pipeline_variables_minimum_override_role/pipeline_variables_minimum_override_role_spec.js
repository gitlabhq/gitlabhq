import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlAlert, GlButton, GlFormGroup, GlFormRadio, GlFormRadioGroup } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import PipelineVariablesMinimumOverrideRole, {
  MINIMUM_ROLE_MAINTAINER,
  MINIMUM_ROLE_DEVELOPER,
} from '~/ci/pipeline_variables_minimum_override_role/pipeline_variables_minimum_override_role.vue';
import updatePipelineVariablesMinimumOverrideRoleProjectSetting from '~/ci/pipeline_variables_minimum_override_role/graphql/mutations/update_pipeline_variables_minimum_override_role_project_setting.mutation.graphql';
import getPipelineVariablesMinimumOverrideRoleProjectSetting from '~/ci/pipeline_variables_minimum_override_role/graphql/queries/get_pipeline_variables_minimum_override_role_project_setting.query.graphql';

Vue.use(VueApollo);

const $toast = {
  show: jest.fn(),
};

const TEST_FULL_PATH = 'project/path';

describe('PipelineVariablesMinimumOverrideRole', () => {
  let wrapper;

  const defaultQueryResponse = jest.fn().mockResolvedValue({
    data: {
      project: {
        id: '1',
        ciCdSettings: {
          pipelineVariablesMinimumOverrideRole: 'maintainer',
        },
      },
    },
  });

  const defaultMutationResponse = jest.fn().mockResolvedValue({
    data: {
      projectCiCdSettingsUpdate: {
        errors: [],
      },
    },
  });

  const createComponent = async ({
    queryHandler = defaultQueryResponse,
    mutationHandler = defaultMutationResponse,
  } = {}) => {
    const apolloProvider = createMockApollo([
      [getPipelineVariablesMinimumOverrideRoleProjectSetting, queryHandler],
      [updatePipelineVariablesMinimumOverrideRoleProjectSetting, mutationHandler],
    ]);

    wrapper = shallowMount(PipelineVariablesMinimumOverrideRole, {
      provide: {
        fullPath: TEST_FULL_PATH,
      },
      mocks: {
        $toast,
      },
      apolloProvider,
    });

    await waitForPromises();
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findRadioButtons = () => wrapper.findAllComponents(GlFormRadio);
  const findSaveButton = () => wrapper.findComponent(GlButton);

  const selectRadioOption = async (value) => {
    findRadioGroup().vm.$emit('input', value);
    const radioButton = findRadioButtons().wrappers.find(
      (btn) => btn.attributes('value') === value,
    );
    radioButton.vm.$emit('change');
    await waitForPromises();
  };

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('on render', () => {
    it('renders the form group with correct label', async () => {
      await createComponent();

      expect(findFormGroup().exists()).toBe(true);
      expect(findFormGroup().attributes('label')).toBe('Minimum role to use pipeline variables');
    });

    it('renders all role options as radio buttons', async () => {
      await createComponent();

      expect(findRadioButtons()).toHaveLength(
        PipelineVariablesMinimumOverrideRole.ROLE_OPTIONS.length,
      );

      PipelineVariablesMinimumOverrideRole.ROLE_OPTIONS.forEach((option, index) => {
        expect(findRadioButtons().at(index).attributes('value')).toBe(option.value);
        expect(findRadioButtons().at(index).text()).toContain(option.text);
      });
    });

    it('has the correct help path', () => {
      expect(PipelineVariablesMinimumOverrideRole.helpPath).toBe(
        helpPagePath('ci/variables/_index', {
          anchor: 'restrict-pipeline-variables',
        }),
      );
    });
  });

  describe('GraphQL operations', () => {
    describe('query', () => {
      it('fetches initial role setting successfully', async () => {
        await createComponent();

        expect(defaultQueryResponse).toHaveBeenCalledWith({ fullPath: TEST_FULL_PATH });
        expect(wrapper.vm.minimumOverrideRole).toBe('maintainer');
        expect(findRadioGroup().attributes('checked')).toBe('maintainer');
      });

      it('sets default role to `developer` when query returns null', async () => {
        const queryHandler = jest.fn().mockResolvedValue({
          data: {
            project: null,
          },
        });

        await createComponent({ queryHandler });

        expect(wrapper.vm.minimumOverrideRole).toBe(MINIMUM_ROLE_DEVELOPER);
      });

      it('shows error alert when query fails', async () => {
        const queryHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

        await createComponent({ queryHandler });

        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe(
          'There was a problem fetching the latest minimum override role.',
        );
      });
    });

    describe('mutation', () => {
      it('updates role setting successfully', async () => {
        await createComponent();
        await selectRadioOption(MINIMUM_ROLE_MAINTAINER);
        findSaveButton().vm.$emit('click');

        expect(defaultMutationResponse).toHaveBeenCalledWith({
          fullPath: TEST_FULL_PATH,
          pipelineVariablesMinimumOverrideRole: MINIMUM_ROLE_MAINTAINER,
        });
      });

      it('displays a toast message on success', async () => {
        await createComponent();
        await selectRadioOption(MINIMUM_ROLE_MAINTAINER);
        findSaveButton().vm.$emit('click');
        await waitForPromises();

        expect($toast.show).toHaveBeenCalledWith(
          'Pipeline variable minimum override role successfully updated.',
        );
      });

      it('shows error alert when mutation returns errors', async () => {
        const mutationHandler = jest.fn().mockResolvedValue({
          data: {
            namespaceSettingsUpdate: {
              errors: [{ message: 'Update failed' }],
            },
          },
        });

        await createComponent({ mutationHandler });
        await selectRadioOption(MINIMUM_ROLE_MAINTAINER);
        findSaveButton().vm.$emit('click');
        await waitForPromises();

        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe(
          'There was a problem updating the minimum override setting.',
        );
      });

      it('shows error alert when mutation fails', async () => {
        const mutationHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

        await createComponent({ mutationHandler });
        await selectRadioOption(MINIMUM_ROLE_MAINTAINER);
        findSaveButton().vm.$emit('click');
        await waitForPromises();

        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe(
          'There was a problem updating the minimum override setting.',
        );
      });
    });
  });
});
