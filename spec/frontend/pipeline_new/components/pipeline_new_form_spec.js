import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlForm, GlDropdownItem, GlSprintf, GlLoadingIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import CreditCardValidationRequiredAlert from 'ee_component/billings/components/cc_validation_required_alert.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';
import { redirectTo } from '~/lib/utils/url_utility';
import PipelineNewForm from '~/pipeline_new/components/pipeline_new_form.vue';
import ciConfigVariablesQuery from '~/pipeline_new/graphql/queries/ci_config_variables.graphql';
import { resolvers } from '~/pipeline_new/graphql/resolvers';
import RefsDropdown from '~/pipeline_new/components/refs_dropdown.vue';
import {
  mockCreditCardValidationRequiredError,
  mockCiConfigVariablesResponse,
  mockCiConfigVariablesResponseWithoutDesc,
  mockEmptyCiConfigVariablesResponse,
  mockError,
  mockQueryParams,
  mockPostParams,
  mockProjectId,
  mockRefs,
  mockYamlVariables,
} from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  redirectTo: jest.fn(),
}));

const projectRefsEndpoint = '/root/project/refs';
const pipelinesPath = '/root/project/-/pipelines';
const projectPath = '/root/project/-/pipelines/config_variables';
const newPipelinePostResponse = { id: 1 };
const defaultBranch = 'main';

describe('Pipeline New Form', () => {
  let wrapper;
  let mock;
  let mockApollo;
  let mockCiConfigVariables;
  let dummySubmitEvent;

  const findForm = () => wrapper.findComponent(GlForm);
  const findRefsDropdown = () => wrapper.findComponent(RefsDropdown);
  const findSubmitButton = () => wrapper.findByTestId('run_pipeline_button');
  const findVariableRows = () => wrapper.findAllByTestId('ci-variable-row');
  const findRemoveIcons = () => wrapper.findAllByTestId('remove-ci-variable-row');
  const findVariableTypes = () => wrapper.findAllByTestId('pipeline-form-ci-variable-type');
  const findKeyInputs = () => wrapper.findAllByTestId('pipeline-form-ci-variable-key');
  const findValueInputs = () => wrapper.findAllByTestId('pipeline-form-ci-variable-value');
  const findValueDropdowns = () =>
    wrapper.findAllByTestId('pipeline-form-ci-variable-value-dropdown');
  const findValueDropdownItems = (dropdown) => dropdown.findAllComponents(GlDropdownItem);
  const findErrorAlert = () => wrapper.findByTestId('run-pipeline-error-alert');
  const findWarningAlert = () => wrapper.findByTestId('run-pipeline-warning-alert');
  const findWarningAlertSummary = () => findWarningAlert().findComponent(GlSprintf);
  const findWarnings = () => wrapper.findAllByTestId('run-pipeline-warning');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findCCAlert = () => wrapper.findComponent(CreditCardValidationRequiredAlert);
  const getFormPostParams = () => JSON.parse(mock.history.post[0].data);

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
    input.element.value = value;
    input.trigger('change');

    await nextTick();
  };

  const createComponentWithApollo = ({ method = shallowMountExtended, props = {} } = {}) => {
    const handlers = [[ciConfigVariablesQuery, mockCiConfigVariables]];
    mockApollo = createMockApollo(handlers, resolvers);

    wrapper = method(PipelineNewForm, {
      apolloProvider: mockApollo,
      provide: {
        projectRefsEndpoint,
      },
      propsData: {
        projectId: mockProjectId,
        pipelinesPath,
        projectPath,
        defaultBranch,
        refParam: defaultBranch,
        settingsLink: '',
        maxWarnings: 25,
        ...props,
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mockCiConfigVariables = jest.fn();
    mock.onGet(projectRefsEndpoint).reply(HTTP_STATUS_OK, mockRefs);

    dummySubmitEvent = {
      preventDefault: jest.fn(),
    };
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
  });

  describe('Form', () => {
    beforeEach(async () => {
      mockCiConfigVariables.mockResolvedValue(mockEmptyCiConfigVariablesResponse);
      createComponentWithApollo({ props: mockQueryParams, method: mountExtended });
      await waitForPromises();
    });

    it('displays the correct values for the provided query params', async () => {
      expect(findVariableTypes().at(0).props('text')).toBe('Variable');
      expect(findVariableTypes().at(1).props('text')).toBe('File');
      expect(findRefsDropdown().props('value')).toEqual({ shortName: 'tag-1' });
      expect(findVariableRows()).toHaveLength(3);
    });

    it('displays a variable from provided query params', () => {
      expect(findKeyInputs().at(0).element.value).toBe('test_var');
      expect(findValueInputs().at(0).element.value).toBe('test_var_val');
    });

    it('displays an empty variable for the user to fill out', async () => {
      expect(findKeyInputs().at(2).element.value).toBe('');
      expect(findValueInputs().at(2).element.value).toBe('');
      expect(findVariableTypes().at(2).props('text')).toBe('Variable');
    });

    it('does not display remove icon for last row', () => {
      expect(findRemoveIcons()).toHaveLength(2);
    });

    it('removes ci variable row on remove icon button click', async () => {
      findRemoveIcons().at(1).trigger('click');

      await nextTick();

      expect(findVariableRows()).toHaveLength(2);
    });

    it('creates blank variable on input change event', async () => {
      const input = findKeyInputs().at(2);
      input.element.value = 'test_var_2';
      input.trigger('change');

      await nextTick();

      expect(findVariableRows()).toHaveLength(4);
      expect(findKeyInputs().at(3).element.value).toBe('');
      expect(findValueInputs().at(3).element.value).toBe('');
    });
  });

  describe('Pipeline creation', () => {
    beforeEach(async () => {
      mockCiConfigVariables.mockResolvedValue(mockEmptyCiConfigVariablesResponse);
      mock.onPost(pipelinesPath).reply(HTTP_STATUS_OK, newPipelinePostResponse);
    });

    it('does not submit the native HTML form', async () => {
      createComponentWithApollo();

      findForm().vm.$emit('submit', dummySubmitEvent);

      expect(dummySubmitEvent.preventDefault).toHaveBeenCalled();
    });

    it('disables the submit button immediately after submitting', async () => {
      createComponentWithApollo();

      expect(findSubmitButton().props('disabled')).toBe(false);

      findForm().vm.$emit('submit', dummySubmitEvent);
      await waitForPromises();

      expect(findSubmitButton().props('disabled')).toBe(true);
    });

    it('creates pipeline with full ref and variables', async () => {
      createComponentWithApollo();

      findForm().vm.$emit('submit', dummySubmitEvent);
      await waitForPromises();

      expect(getFormPostParams().ref).toEqual(`refs/heads/${defaultBranch}`);
      expect(redirectTo).toHaveBeenCalledWith(`${pipelinesPath}/${newPipelinePostResponse.id}`);
    });

    it('creates a pipeline with short ref and variables from the query params', async () => {
      createComponentWithApollo({ props: mockQueryParams });

      await waitForPromises();

      findForm().vm.$emit('submit', dummySubmitEvent);

      await waitForPromises();

      expect(getFormPostParams()).toEqual(mockPostParams);
      expect(redirectTo).toHaveBeenCalledWith(`${pipelinesPath}/${newPipelinePostResponse.id}`);
    });
  });

  describe('When the ref has been changed', () => {
    beforeEach(async () => {
      mockCiConfigVariables.mockResolvedValue(mockEmptyCiConfigVariablesResponse);
      createComponentWithApollo({ method: mountExtended });

      await waitForPromises();
    });

    it('variables persist between ref changes', async () => {
      await selectBranch('main');
      await changeKeyInputValue(0, 'build_var');

      await selectBranch('branch-1');
      await changeKeyInputValue(0, 'deploy_var');

      await selectBranch('main');

      expect(findKeyInputs().at(0).element.value).toBe('build_var');
      expect(findVariableRows().length).toBe(2);

      await selectBranch('branch-1');

      expect(findKeyInputs().at(0).element.value).toBe('deploy_var');
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

  describe('when yml defines a variable', () => {
    it('loading icon is shown when content is requested and hidden when received', async () => {
      mockCiConfigVariables.mockResolvedValue(mockEmptyCiConfigVariablesResponse);
      createComponentWithApollo({ props: mockQueryParams, method: mountExtended });

      expect(findLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    describe('with different predefined values', () => {
      beforeEach(async () => {
        mockCiConfigVariables.mockResolvedValue(mockCiConfigVariablesResponse);
        createComponentWithApollo({ method: mountExtended });
        await waitForPromises();
      });

      it('multi-line strings are added to the value field without removing line breaks', () => {
        expect(findValueInputs().at(1).element.value).toBe(mockYamlVariables[1].value);
      });

      it('multiple predefined values are rendered as a dropdown', () => {
        const dropdown = findValueDropdowns().at(0);
        const dropdownItems = findValueDropdownItems(dropdown);
        const { valueOptions } = mockYamlVariables[2];

        expect(dropdownItems.at(0).text()).toBe(valueOptions[0]);
        expect(dropdownItems.at(1).text()).toBe(valueOptions[1]);
        expect(dropdownItems.at(2).text()).toBe(valueOptions[2]);
      });

      it('variable with multiple predefined values sets value as the default', () => {
        const dropdown = findValueDropdowns().at(0);
        const { valueOptions } = mockYamlVariables[2];

        expect(dropdown.props('text')).toBe(valueOptions[1]);
      });
    });

    describe('with description', () => {
      beforeEach(async () => {
        mockCiConfigVariables.mockResolvedValue(mockCiConfigVariablesResponse);
        createComponentWithApollo({ props: mockQueryParams, method: mountExtended });
        await waitForPromises();
      });

      it('displays all the variables', async () => {
        expect(findVariableRows()).toHaveLength(6);
      });

      it('displays a variable from yml', () => {
        expect(findKeyInputs().at(0).element.value).toBe(mockYamlVariables[0].key);
        expect(findValueInputs().at(0).element.value).toBe(mockYamlVariables[0].value);
      });

      it('displays a variable from provided query params', () => {
        expect(findKeyInputs().at(3).element.value).toBe(
          Object.keys(mockQueryParams.variableParams)[0],
        );
        expect(findValueInputs().at(3).element.value).toBe(
          Object.values(mockQueryParams.fileParams)[0],
        );
      });

      it('adds a description to the first variable from yml', () => {
        expect(findVariableRows().at(0).text()).toContain(mockYamlVariables[0].description);
      });

      it('removes the description when a variable key changes', async () => {
        findKeyInputs().at(0).element.value = 'yml_var_modified';
        findKeyInputs().at(0).trigger('change');

        await nextTick();

        expect(findVariableRows().at(0).text()).not.toContain(mockYamlVariables[0].description);
      });
    });

    describe('without description', () => {
      beforeEach(async () => {
        mockCiConfigVariables.mockResolvedValue(mockCiConfigVariablesResponseWithoutDesc);
        createComponentWithApollo({ method: mountExtended });
        await waitForPromises();
      });

      it('displays variables with description only', async () => {
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
          .onGet(projectRefsEndpoint, { params: { search: '' } })
          .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        findRefsDropdown().vm.$emit('loadingError');
      });

      it('shows both an error alert', () => {
        expect(findErrorAlert().exists()).toBe(true);
        expect(findWarningAlert().exists()).toBe(false);
      });
    });

    describe('when the error response can be handled', () => {
      beforeEach(async () => {
        mock.onPost(pipelinesPath).reply(HTTP_STATUS_BAD_REQUEST, mockError);

        findForm().vm.$emit('submit', dummySubmitEvent);

        await waitForPromises();
      });

      it('shows both error and warning', () => {
        expect(findErrorAlert().exists()).toBe(true);
        expect(findWarningAlert().exists()).toBe(true);
      });

      it('shows the correct error', () => {
        expect(findErrorAlert().text()).toBe(mockError.errors[0]);
      });

      it('shows the correct warning title', () => {
        const { length } = mockError.warnings;

        expect(findWarningAlertSummary().attributes('message')).toBe(`${length} warnings found:`);
      });

      it('shows the correct amount of warnings', () => {
        expect(findWarnings()).toHaveLength(mockError.warnings.length);
      });

      it('re-enables the submit button', () => {
        expect(findSubmitButton().props('disabled')).toBe(false);
      });

      it('does not show the credit card validation required alert', () => {
        expect(findCCAlert().exists()).toBe(false);
      });

      describe('when the error response is credit card validation required', () => {
        beforeEach(async () => {
          mock
            .onPost(pipelinesPath)
            .reply(HTTP_STATUS_BAD_REQUEST, mockCreditCardValidationRequiredError);

          window.gon = {
            subscriptions_url: TEST_HOST,
            payment_form_url: TEST_HOST,
          };

          findForm().vm.$emit('submit', dummySubmitEvent);

          await waitForPromises();
        });

        it('shows credit card validation required alert', () => {
          expect(findErrorAlert().exists()).toBe(false);
          expect(findCCAlert().exists()).toBe(true);
        });

        it('clears error and hides the alert on dismiss', async () => {
          expect(findCCAlert().exists()).toBe(true);
          expect(wrapper.vm.$data.error).toBe(mockCreditCardValidationRequiredError.errors[0]);

          findCCAlert().vm.$emit('dismiss');

          await nextTick();

          expect(findCCAlert().exists()).toBe(false);
          expect(wrapper.vm.$data.error).toBe(null);
        });
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
});
