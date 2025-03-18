import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlButton, GlFormGroup, GlFormRadio, GlFormRadioGroup } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PipelineVariablesDefaultRole, {
  DEFAULT_ROLE_MAINTAINER,
  DEFAULT_ROLE_NO_ONE,
} from '~/group_settings/pipeline_variables_default_role/pipeline_variables_default_role.vue';
import updatePipelineVariablesDefaultRoleSetting from '~/group_settings/pipeline_variables_default_role/graphql/mutations/update_pipeline_variables_default_role_group_setting.mutation.graphql';
import getPipelineVariablesDefaultRoleSetting from '~/group_settings/pipeline_variables_default_role/graphql/queries/get_pipeline_variables_default_role_group_setting.query.graphql';

Vue.use(VueApollo);
jest.mock('~/alert');
const $toast = {
  show: jest.fn(),
};

const TEST_FULL_PATH = 'group/project';

describe('PipelineVariablesDefaultRole', () => {
  let wrapper;

  const defaultQueryResponse = jest.fn().mockResolvedValue({
    data: {
      group: {
        id: '1',
        ciCdSettings: {
          pipelineVariablesDefaultRole: 'developer',
        },
      },
    },
  });

  const defaultMutationResponse = jest.fn().mockResolvedValue({
    data: {
      namespaceSettingsUpdate: {
        errors: [],
      },
    },
  });

  const createComponent = async ({
    queryHandler = defaultQueryResponse,
    mutationHandler = defaultMutationResponse,
  } = {}) => {
    const apolloProvider = createMockApollo([
      [getPipelineVariablesDefaultRoleSetting, queryHandler],
      [updatePipelineVariablesDefaultRoleSetting, mutationHandler],
    ]);

    wrapper = shallowMount(PipelineVariablesDefaultRole, {
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

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findRadioButtons = () => wrapper.findAllComponents(GlFormRadio);
  const findSaveButton = () => wrapper.findComponent(GlButton);

  const selectRadioOption = async (value, index) => {
    findRadioGroup().vm.$emit('input', value);
    findRadioButtons().at(index).vm.$emit('change');
    await waitForPromises();
  };

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('on render', () => {
    it('renders the form group with correct label', async () => {
      await createComponent();

      expect(findFormGroup().exists()).toBe(true);
      expect(findFormGroup().attributes('label')).toBe('Default role to use pipeline variables');
    });

    it('renders all role options as radio buttons', async () => {
      await createComponent();

      expect(findRadioButtons()).toHaveLength(PipelineVariablesDefaultRole.ROLE_OPTIONS.length);

      PipelineVariablesDefaultRole.ROLE_OPTIONS.forEach((option, index) => {
        expect(findRadioButtons().at(index).attributes('value')).toBe(option.value);
        expect(findRadioButtons().at(index).text()).toContain(option.text);
      });
    });

    it('has the correct help path', () => {
      expect(PipelineVariablesDefaultRole.helpPath).toBe(
        helpPagePath('ci/variables/_index', {
          anchor: 'cicd-variable-precedence',
        }),
      );
    });
  });

  describe('GraphQL operations', () => {
    describe('query', () => {
      it('fetches initial role setting successfully', async () => {
        await createComponent();

        expect(defaultQueryResponse).toHaveBeenCalledWith({ fullPath: TEST_FULL_PATH });
        expect(findRadioButtons().at(3).attributes('value')).toBe('DEVELOPER');
        expect(wrapper.vm.pipelineVariablesDefaultRole).toBe('DEVELOPER');
      });

      it('sets default role to NO_ONE_ALLOWED when query returns null', async () => {
        const queryHandler = jest.fn().mockResolvedValue({
          data: {
            group: null,
          },
        });

        await createComponent({ queryHandler });

        expect(wrapper.vm.pipelineVariablesDefaultRole).toBe(DEFAULT_ROLE_NO_ONE);
      });

      it('shows error alert when query fails', async () => {
        const queryHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

        await createComponent({ queryHandler });

        expect(createAlert).toHaveBeenCalledWith({
          message: 'There was a problem fetching the pipeline variables default role.',
        });
      });
    });

    describe('mutation', () => {
      it('updates role setting successfully', async () => {
        await createComponent();
        await selectRadioOption(DEFAULT_ROLE_MAINTAINER, 2);
        findSaveButton().vm.$emit('click');

        expect(defaultMutationResponse).toHaveBeenCalledWith({
          fullPath: TEST_FULL_PATH,
          pipelineVariablesDefaultRole: DEFAULT_ROLE_MAINTAINER,
        });
      });

      it('displays a toast message on success', async () => {
        await createComponent();
        await selectRadioOption(DEFAULT_ROLE_MAINTAINER, 2);
        findSaveButton().vm.$emit('click');
        await waitForPromises();

        expect($toast.show).toHaveBeenCalledWith(
          'Pipeline variable access role successfully updated.',
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
        await selectRadioOption(DEFAULT_ROLE_MAINTAINER, 2);
        findSaveButton().vm.$emit('click');
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'Update failed',
        });
      });

      it('shows error alert when mutation fails', async () => {
        const mutationHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

        await createComponent({ mutationHandler });
        await selectRadioOption(DEFAULT_ROLE_MAINTAINER, 2);
        findSaveButton().vm.$emit('click');
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'There was a problem updating the pipeline variables default role setting.',
        });
      });
    });
  });
});
