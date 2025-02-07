import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlForm, GlLoadingIcon, GlIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import mockPipelineCreateMutationResponse from 'test_fixtures/graphql/pipelines/create_pipeline.mutation.graphql.json';
import mockPipelineCreateMutationErrorResponse from 'test_fixtures/graphql/pipelines/create_pipeline_error.mutation.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import PipelineNewForm, {
  POLLING_INTERVAL,
} from '~/ci/pipeline_new/components/pipeline_new_form.vue';
import ciConfigVariablesQuery from '~/ci/pipeline_new/graphql/queries/ci_config_variables.graphql';
import pipelineCreateMutation from '~/ci/pipeline_new/graphql/mutations/create_pipeline.mutation.graphql';
import RefsDropdown from '~/ci/pipeline_new/components/refs_dropdown.vue';
import VariableValuesListbox from '~/ci/pipeline_new/components/variable_values_listbox.vue';
import {
  mockCiConfigVariablesResponse,
  mockCiConfigVariablesResponseWithoutDesc,
  mockEmptyCiConfigVariablesResponse,
  mockNoCachedCiConfigVariablesResponse,
  mockQueryParams,
  mockProjectId,
  mockYamlVariables,
  mockPipelineConfigButtonText,
} from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  joinPaths: jest.fn(),
  setUrlFragment: jest.fn(),
}));

const pipelinesPath = '/root/project/-/pipelines';
const pipelinesEditorPath = '/root/project/-/ci/editor';
const projectPath = '/root/project/-/pipelines/config_variables';
const defaultBranch = 'main';

describe('Pipeline New Form', () => {
  let wrapper;
  let mock;
  let mockApollo;
  let mockCiConfigVariables;
  let dummySubmitEvent;

  const pipelineCreateMutationHandler = jest.fn();

  const findForm = () => wrapper.findComponent(GlForm);
  const findRefsDropdown = () => wrapper.findComponent(RefsDropdown);
  const findSubmitButton = () => wrapper.findByTestId('run-pipeline-button');
  const findVariableRows = () => wrapper.findAllByTestId('ci-variable-row-container');
  const findRemoveIcons = () => wrapper.findAllByTestId('remove-ci-variable-row');
  const findCollapsableListsWithVariableTypes = () =>
    wrapper.findAllByTestId('pipeline-form-ci-variable-type');
  const findKeyInputs = () => wrapper.findAllByTestId('pipeline-form-ci-variable-key-field');
  const findValueInputs = () => wrapper.findAllByTestId('pipeline-form-ci-variable-value-field');
  const findCollapsableListWithVariableOptions = () => wrapper.findComponent(VariableValuesListbox);
  const findErrorAlert = () => wrapper.findByTestId('run-pipeline-error-alert');
  const findPipelineConfigButton = () => wrapper.findByTestId('ci-cd-pipeline-configuration');
  const findWarningAlert = () => wrapper.findByTestId('run-pipeline-warning-alert');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findCiCdSettingsLink = () => wrapper.findByTestId('ci-cd-settings-link');

  const advanceToNextFetch = (milliseconds) => {
    jest.advanceTimersByTime(milliseconds);
  };

  const selectBranch = async (branch) => {
    // Select a branch in the dropdown
    findRefsDropdown().vm.$emit('input', {
      shortName: branch,
      fullName: `refs/heads/${branch}`,
    });

    await waitForPromises();
  };

  const changeKeyInputValue = async (keyInputIndex, value) => {
    const input = findKeyInputs().at(keyInputIndex);
    input.vm.$emit('input', value);
    input.vm.$emit('change');

    await nextTick();
  };

  const createComponentWithApollo = ({
    props = {},
    mountFn = shallowMountExtended,
    stubs = {},
  } = {}) => {
    const handlers = [
      [ciConfigVariablesQuery, mockCiConfigVariables],
      [pipelineCreateMutation, pipelineCreateMutationHandler],
    ];
    mockApollo = createMockApollo(handlers);

    wrapper = mountFn(PipelineNewForm, {
      apolloProvider: mockApollo,
      provide: {
        identityVerificationRequired: true,
        identityVerificationPath: '/test',
      },
      propsData: {
        projectId: mockProjectId,
        pipelinesPath,
        pipelinesEditorPath,
        canViewPipelineEditor: true,
        projectPath,
        defaultBranch,
        refParam: defaultBranch,
        settingsLink: '',
        maxWarnings: 25,
        isMaintainer: true,
        ...props,
      },
      stubs,
    });
  };

  const glFormGroupStub = {
    'gl-form-group': {
      template: '<div><slot name="description"></slot></div>',
    },
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mockCiConfigVariables = jest.fn();

    dummySubmitEvent = {
      preventDefault: jest.fn(),
    };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('Form', () => {
    beforeEach(async () => {
      mockCiConfigVariables.mockResolvedValue(mockEmptyCiConfigVariablesResponse);
      createComponentWithApollo({ props: mockQueryParams });
      await waitForPromises();
    });

    it('displays the correct values for the provided query params', () => {
      const collapsableLists = findCollapsableListsWithVariableTypes();

      expect(collapsableLists.at(0).props('selected')).toBe('env_var');
      expect(collapsableLists.at(1).props('selected')).toBe('file');
      expect(findRefsDropdown().props('value')).toEqual({ shortName: 'tag-1' });
      expect(findVariableRows()).toHaveLength(3);
    });

    it('displays a variable from provided query params', () => {
      expect(findKeyInputs().at(0).attributes('value')).toBe('test_var');
      expect(findValueInputs().at(0).attributes('value')).toBe('test_var_val');
    });

    it('displays an empty variable for the user to fill out', () => {
      const collapsableLists = findCollapsableListsWithVariableTypes();

      expect(findKeyInputs().at(2).attributes('value')).toBe('');
      expect(findValueInputs().at(2).attributes('value')).toBe('');
      expect(collapsableLists.at(2).props('selected')).toBe('env_var');
    });

    it('does not display remove icon for last row', () => {
      expect(findRemoveIcons()).toHaveLength(2);
    });

    it('display remove button with specific properties', () => {
      expect(findRemoveIcons().at(0).props('category')).toBe('tertiary');
      expect(findRemoveIcons().at(0).props('variant')).toBe('default');
      expect(findRemoveIcons().at(0).findComponent(GlIcon).props('name')).toBe('remove');
    });

    it('removes ci variable row on remove icon button click', async () => {
      findRemoveIcons().at(1).vm.$emit('click');

      await nextTick();

      expect(findVariableRows()).toHaveLength(2);
    });

    it('creates blank variable on input change event', async () => {
      const input = findKeyInputs().at(2);

      input.vm.$emit('input', 'test_var_2');
      input.vm.$emit('change');

      await nextTick();

      expect(findVariableRows()).toHaveLength(4);
      expect(findKeyInputs().at(3).attributes('value')).toBe('');
      expect(findValueInputs().at(3).attributes('value')).toBe('');
    });
  });

  describe('Pipeline creation', () => {
    beforeEach(() => {
      mockCiConfigVariables.mockResolvedValue(mockEmptyCiConfigVariablesResponse);
      pipelineCreateMutationHandler.mockResolvedValue(mockPipelineCreateMutationResponse);
    });

    it('does not submit the native HTML form', () => {
      createComponentWithApollo();

      findForm().vm.$emit('submit', dummySubmitEvent);

      expect(dummySubmitEvent.preventDefault).toHaveBeenCalled();
    });

    it('disables the submit button immediately after submitting', async () => {
      createComponentWithApollo();

      expect(findSubmitButton().props('disabled')).toBe(false);

      await findForm().vm.$emit('submit', dummySubmitEvent);

      expect(findSubmitButton().props('disabled')).toBe(true);
    });

    it('fires the mutation when the submit button is clicked', async () => {
      createComponentWithApollo();

      findForm().vm.$emit('submit', dummySubmitEvent);
      await waitForPromises();

      expect(pipelineCreateMutationHandler).toHaveBeenCalled();
    });

    it('creates pipeline with ref and variables', async () => {
      createComponentWithApollo();

      findForm().vm.$emit('submit', dummySubmitEvent);
      await waitForPromises();

      expect(pipelineCreateMutationHandler).toHaveBeenCalledWith({
        input: {
          ref: 'main',
          projectPath: '/root/project/-/pipelines/config_variables',
          variables: [],
        },
      });
    });

    it('navigates to the created pipeline', async () => {
      const pipelinePath = mockPipelineCreateMutationResponse.data.pipelineCreate.pipeline.path;

      createComponentWithApollo();
      await waitForPromises();

      findForm().vm.$emit('submit', dummySubmitEvent);
      await waitForPromises();

      expect(visitUrl).toHaveBeenCalledWith(pipelinePath);
    });
  });

  describe('When the ref has been changed', () => {
    beforeEach(async () => {
      mockCiConfigVariables.mockResolvedValue(mockEmptyCiConfigVariablesResponse);
      createComponentWithApollo();

      await waitForPromises();
    });

    it('variables persist between ref changes', async () => {
      await selectBranch('main');
      await changeKeyInputValue(0, 'build_var');

      await selectBranch('branch-1');
      await changeKeyInputValue(0, 'deploy_var');

      await selectBranch('main');

      expect(findKeyInputs().at(0).attributes('value')).toBe('build_var');
      expect(findVariableRows().length).toBe(2);

      await selectBranch('branch-1');

      expect(findKeyInputs().at(0).attributes('value')).toBe('deploy_var');
      expect(findVariableRows().length).toBe(2);
    });

    it('skips query call when form variables are already cached', async () => {
      await selectBranch('main');
      await changeKeyInputValue(0, 'build_var');

      expect(mockCiConfigVariables).toHaveBeenCalledTimes(1);

      await selectBranch('branch-1');

      expect(mockCiConfigVariables).toHaveBeenCalledTimes(2);

      // no additional call since `main` form values have been cached
      await selectBranch('main');

      expect(mockCiConfigVariables).toHaveBeenCalledTimes(2);
    });
  });

  describe('When there are no variables in the API cache', () => {
    beforeEach(async () => {
      mockCiConfigVariables.mockResolvedValue(mockNoCachedCiConfigVariablesResponse);
      createComponentWithApollo();
      await waitForPromises();
    });

    it('stops polling after CONFIG_VARIABLES_TIMEOUT ms have passed', async () => {
      advanceToNextFetch(POLLING_INTERVAL);
      await waitForPromises();

      advanceToNextFetch(POLLING_INTERVAL);
      await waitForPromises();

      expect(mockCiConfigVariables).toHaveBeenCalledTimes(3);

      advanceToNextFetch(POLLING_INTERVAL);
      await waitForPromises();

      expect(mockCiConfigVariables).toHaveBeenCalledTimes(3);
    });

    it('shows loading icon while query polls for updated values', async () => {
      expect(findLoadingIcon().exists()).toBe(true);
      expect(mockCiConfigVariables).toHaveBeenCalledTimes(1);

      advanceToNextFetch(POLLING_INTERVAL);
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(mockCiConfigVariables).toHaveBeenCalledTimes(2);
    });

    it('hides loading icon and stops polling after query fetches the updated values', async () => {
      expect(findLoadingIcon().exists()).toBe(true);

      mockCiConfigVariables.mockResolvedValue(mockCiConfigVariablesResponse);
      advanceToNextFetch(POLLING_INTERVAL);
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(mockCiConfigVariables).toHaveBeenCalledTimes(2);

      advanceToNextFetch(POLLING_INTERVAL);
      await waitForPromises();

      expect(mockCiConfigVariables).toHaveBeenCalledTimes(2);
    });
  });

  const testBehaviorWhenCacheIsPopulated = (queryResponse) => {
    beforeEach(() => {
      mockCiConfigVariables.mockResolvedValue(queryResponse);
      createComponentWithApollo();
    });

    it('does not poll for new values', async () => {
      await waitForPromises();

      expect(mockCiConfigVariables).toHaveBeenCalledTimes(1);

      advanceToNextFetch(POLLING_INTERVAL);
      await waitForPromises();

      expect(mockCiConfigVariables).toHaveBeenCalledTimes(1);
    });

    it('loading icon is shown when content is requested and hidden when received', async () => {
      mockCiConfigVariables.mockResolvedValue(mockEmptyCiConfigVariablesResponse);
      createComponentWithApollo({ props: mockQueryParams });

      expect(findLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });
  };

  describe('When no variables are defined in the CI configuration and the cache is updated', () => {
    testBehaviorWhenCacheIsPopulated(mockEmptyCiConfigVariablesResponse);

    it('displays an empty form', async () => {
      mockCiConfigVariables.mockResolvedValue(mockEmptyCiConfigVariablesResponse);
      createComponentWithApollo();
      await waitForPromises();

      const collapsableLists = findCollapsableListsWithVariableTypes();

      expect(findKeyInputs().at(0).attributes('value')).toBe('');
      expect(findValueInputs().at(0).attributes('value')).toBe('');
      expect(collapsableLists.at(0).props('selected')).toBe('env_var');
    });
  });

  describe('When CI configuration has defined variables and they are stored in the cache', () => {
    testBehaviorWhenCacheIsPopulated(mockCiConfigVariablesResponse);

    describe('with different predefined values', () => {
      beforeEach(async () => {
        mockCiConfigVariables.mockResolvedValue(mockCiConfigVariablesResponse);
        createComponentWithApollo();
        await waitForPromises();
      });

      it('multi-line strings are added to the value field without removing line breaks', () => {
        expect(findValueInputs().at(1).attributes('value')).toBe(mockYamlVariables[1].value);
      });

      it('passes the correct data to the collapsible list, which will be displayed as items of the collapsible list', () => {
        const collapsableList = findCollapsableListWithVariableOptions();
        const expectedItems = mockYamlVariables[2].valueOptions.map((item) => ({
          text: item,
          value: item,
        }));

        expect(collapsableList.props('items')).toMatchObject(expectedItems);
      });

      it('passes the correct default variable option value to the collapsable list', () => {
        const collapsableList = findCollapsableListWithVariableOptions();
        const { valueOptions } = mockYamlVariables[2];

        expect(collapsableList.props('selected')).toBe(valueOptions[1]);
      });
    });

    describe('with description', () => {
      beforeEach(async () => {
        mockCiConfigVariables.mockResolvedValue(mockCiConfigVariablesResponse);
        createComponentWithApollo({ props: mockQueryParams });
        await waitForPromises();
      });

      it('displays all the variables', () => {
        expect(findVariableRows()).toHaveLength(6);
      });

      it('displays a variable from yml', () => {
        expect(findKeyInputs().at(0).attributes('value')).toBe(mockYamlVariables[0].key);
        expect(findValueInputs().at(0).attributes('value')).toBe(mockYamlVariables[0].value);
      });

      it('displays a variable from provided query params', () => {
        expect(findKeyInputs().at(3).attributes('value')).toBe(
          Object.keys(mockQueryParams.variableParams)[0],
        );
        expect(findValueInputs().at(3).attributes('value')).toBe(
          Object.values(mockQueryParams.fileParams)[0],
        );
      });

      it('adds a description to the first variable from yml', () => {
        expect(findVariableRows().at(0).text()).toContain(mockYamlVariables[0].description);
      });

      it('removes the description when a variable key changes', async () => {
        findKeyInputs().at(0).vm.$emit('input', 'yml_var_modified');
        findKeyInputs().at(0).trigger('change');

        await nextTick();

        expect(findVariableRows().at(0).text()).not.toContain(mockYamlVariables[0].description);
      });
    });

    describe('without description', () => {
      beforeEach(async () => {
        mockCiConfigVariables.mockResolvedValue(mockCiConfigVariablesResponseWithoutDesc);
        createComponentWithApollo();
        await waitForPromises();
      });

      it('displays variables with description only', () => {
        expect(findVariableRows()).toHaveLength(2); // extra empty variable is added at the end
      });
    });
  });

  describe('Form errors and warnings', () => {
    beforeEach(() => {
      mockCiConfigVariables.mockResolvedValue(mockEmptyCiConfigVariablesResponse);
      createComponentWithApollo();
    });

    describe('when the refs cannot be loaded', () => {
      beforeEach(() => {
        mock
          .onGet('/api/v4/projects/8/repository/branches', { params: { search: '' } })
          .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        findRefsDropdown().vm.$emit('loadingError');
      });

      it('shows an error alert', () => {
        expect(findErrorAlert().exists()).toBe(true);
        expect(findWarningAlert().exists()).toBe(false);
      });
    });

    describe('when pipeline creation mutation is not successful', () => {
      beforeEach(async () => {
        pipelineCreateMutationHandler.mockResolvedValue(mockPipelineCreateMutationErrorResponse);

        findForm().vm.$emit('submit', dummySubmitEvent);

        await waitForPromises();
      });

      it('shows error', () => {
        expect(findErrorAlert().exists()).toBe(true);
      });

      it('shows the correct error', () => {
        const error = mockPipelineCreateMutationErrorResponse.data.pipelineCreate.errors[0];

        expect(findErrorAlert().text()).toBe(error);
      });

      it('re-enables the submit button', () => {
        expect(findSubmitButton().props('disabled')).toBe(false);
      });

      it('shows pipeline configuration button for user who can view', () => {
        expect(findPipelineConfigButton().exists()).toBe(true);
        expect(findPipelineConfigButton().text()).toBe(mockPipelineConfigButtonText);
      });

      it('does not show pipeline configuration button for user who can not view', () => {
        createComponentWithApollo({ props: { canViewPipelineEditor: false } });

        expect(findPipelineConfigButton().exists()).toBe(false);
      });
    });

    describe('when the error response cannot be handled', () => {
      beforeEach(async () => {
        mock.onPost(pipelinesPath).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, 'something went wrong');

        findForm().vm.$emit('submit', dummySubmitEvent);

        await waitForPromises();
      });

      it('re-enables the submit button', () => {
        expect(findSubmitButton().props('disabled')).toBe(false);
      });
    });
  });

  describe('CI/CD settings page link', () => {
    describe('when the user has a maintainer plus role', () => {
      beforeEach(async () => {
        mockCiConfigVariables.mockResolvedValue(mockCiConfigVariablesResponse);
        createComponentWithApollo({
          props: { isMaintainer: true, settingsLink: 'link' },
          mountFn: mountExtended,
          stubs: glFormGroupStub,
        });
        await waitForPromises();
      });

      it('displays the link', () => {
        expect(findCiCdSettingsLink().exists()).toBe(true);
      });
    });

    describe('when the user is not a maintainer or owner', () => {
      beforeEach(async () => {
        mockCiConfigVariables.mockResolvedValue(mockCiConfigVariablesResponse);
        createComponentWithApollo({
          props: { isMaintainer: false },
          mountFn: mountExtended,
          stubs: glFormGroupStub,
        });
        await waitForPromises();
      });

      it('does not display the link', () => {
        expect(findCiCdSettingsLink().exists()).toBe(false);
      });
    });
  });
});
