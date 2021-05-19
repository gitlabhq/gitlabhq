import { GlForm, GlSprintf, GlLoadingIcon } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import CreditCardValidationRequiredAlert from 'ee_component/billings/components/cc_validation_required_alert.vue';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import httpStatusCodes from '~/lib/utils/http_status';
import { redirectTo } from '~/lib/utils/url_utility';
import PipelineNewForm from '~/pipeline_new/components/pipeline_new_form.vue';
import RefsDropdown from '~/pipeline_new/components/refs_dropdown.vue';
import {
  mockQueryParams,
  mockPostParams,
  mockProjectId,
  mockError,
  mockRefs,
  mockCreditCardValidationRequiredError,
} from '../mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  redirectTo: jest.fn(),
}));

const projectRefsEndpoint = '/root/project/refs';
const pipelinesPath = '/root/project/-/pipelines';
const configVariablesPath = '/root/project/-/pipelines/config_variables';
const newPipelinePostResponse = { id: 1 };
const defaultBranch = 'main';

describe('Pipeline New Form', () => {
  let wrapper;
  let mock;
  let dummySubmitEvent;

  const findForm = () => wrapper.find(GlForm);
  const findRefsDropdown = () => wrapper.findComponent(RefsDropdown);
  const findSubmitButton = () => wrapper.find('[data-testid="run_pipeline_button"]');
  const findVariableRows = () => wrapper.findAll('[data-testid="ci-variable-row"]');
  const findRemoveIcons = () => wrapper.findAll('[data-testid="remove-ci-variable-row"]');
  const findKeyInputs = () => wrapper.findAll('[data-testid="pipeline-form-ci-variable-key"]');
  const findValueInputs = () => wrapper.findAll('[data-testid="pipeline-form-ci-variable-value"]');
  const findErrorAlert = () => wrapper.find('[data-testid="run-pipeline-error-alert"]');
  const findWarningAlert = () => wrapper.find('[data-testid="run-pipeline-warning-alert"]');
  const findWarningAlertSummary = () => findWarningAlert().find(GlSprintf);
  const findWarnings = () => wrapper.findAll('[data-testid="run-pipeline-warning"]');
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const getFormPostParams = () => JSON.parse(mock.history.post[0].data);

  const selectBranch = (branch) => {
    // Select a branch in the dropdown
    findRefsDropdown().vm.$emit('input', {
      shortName: branch,
      fullName: `refs/heads/${branch}`,
    });
  };

  const createComponent = (props = {}, method = shallowMount) => {
    wrapper = method(PipelineNewForm, {
      provide: {
        projectRefsEndpoint,
      },
      propsData: {
        projectId: mockProjectId,
        pipelinesPath,
        configVariablesPath,
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
    mock.onGet(configVariablesPath).reply(httpStatusCodes.OK, {});
    mock.onGet(projectRefsEndpoint).reply(httpStatusCodes.OK, mockRefs);

    dummySubmitEvent = {
      preventDefault: jest.fn(),
    };
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    mock.restore();
  });

  describe('Form', () => {
    beforeEach(async () => {
      createComponent(mockQueryParams, mount);

      mock.onPost(pipelinesPath).reply(httpStatusCodes.OK, newPipelinePostResponse);

      await waitForPromises();
    });

    it('displays the correct values for the provided query params', async () => {
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
    });

    it('does not display remove icon for last row', () => {
      expect(findRemoveIcons()).toHaveLength(2);
    });

    it('removes ci variable row on remove icon button click', async () => {
      findRemoveIcons().at(1).trigger('click');

      await wrapper.vm.$nextTick();

      expect(findVariableRows()).toHaveLength(2);
    });

    it('creates blank variable on input change event', async () => {
      const input = findKeyInputs().at(2);
      input.element.value = 'test_var_2';
      input.trigger('change');

      await wrapper.vm.$nextTick();

      expect(findVariableRows()).toHaveLength(4);
      expect(findKeyInputs().at(3).element.value).toBe('');
      expect(findValueInputs().at(3).element.value).toBe('');
    });
  });

  describe('Pipeline creation', () => {
    beforeEach(async () => {
      mock.onPost(pipelinesPath).reply(httpStatusCodes.OK, newPipelinePostResponse);

      await waitForPromises();
    });

    it('does not submit the native HTML form', async () => {
      createComponent();

      findForm().vm.$emit('submit', dummySubmitEvent);

      expect(dummySubmitEvent.preventDefault).toHaveBeenCalled();
    });

    it('disables the submit button immediately after submitting', async () => {
      createComponent();

      expect(findSubmitButton().props('disabled')).toBe(false);

      findForm().vm.$emit('submit', dummySubmitEvent);
      await waitForPromises();

      expect(findSubmitButton().props('disabled')).toBe(true);
    });

    it('creates pipeline with full ref and variables', async () => {
      createComponent();

      findForm().vm.$emit('submit', dummySubmitEvent);
      await waitForPromises();

      expect(getFormPostParams().ref).toEqual(`refs/heads/${defaultBranch}`);
      expect(redirectTo).toHaveBeenCalledWith(`${pipelinesPath}/${newPipelinePostResponse.id}`);
    });

    it('creates a pipeline with short ref and variables from the query params', async () => {
      createComponent(mockQueryParams);

      await waitForPromises();

      findForm().vm.$emit('submit', dummySubmitEvent);

      await waitForPromises();

      expect(getFormPostParams()).toEqual(mockPostParams);
      expect(redirectTo).toHaveBeenCalledWith(`${pipelinesPath}/${newPipelinePostResponse.id}`);
    });
  });

  describe('When the ref has been changed', () => {
    beforeEach(async () => {
      createComponent({}, mount);

      await waitForPromises();
    });
    it('variables persist between ref changes', async () => {
      selectBranch('main');

      await waitForPromises();

      const mainInput = findKeyInputs().at(0);
      mainInput.element.value = 'build_var';
      mainInput.trigger('change');

      await wrapper.vm.$nextTick();

      selectBranch('branch-1');

      await waitForPromises();

      const branchOneInput = findKeyInputs().at(0);
      branchOneInput.element.value = 'deploy_var';
      branchOneInput.trigger('change');

      await wrapper.vm.$nextTick();

      selectBranch('main');

      await waitForPromises();

      expect(findKeyInputs().at(0).element.value).toBe('build_var');
      expect(findVariableRows().length).toBe(2);

      selectBranch('branch-1');

      await waitForPromises();

      expect(findKeyInputs().at(0).element.value).toBe('deploy_var');
      expect(findVariableRows().length).toBe(2);
    });
  });

  describe('when yml defines a variable', () => {
    const mockYmlKey = 'yml_var';
    const mockYmlValue = 'yml_var_val';
    const mockYmlMultiLineValue = `A value
    with multiple
    lines`;
    const mockYmlDesc = 'A var from yml.';

    it('loading icon is shown when content is requested and hidden when received', async () => {
      createComponent(mockQueryParams, mount);

      mock.onGet(configVariablesPath).reply(httpStatusCodes.OK, {
        [mockYmlKey]: {
          value: mockYmlValue,
          description: mockYmlDesc,
        },
      });

      expect(findLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('multi-line strings are added to the value field without removing line breaks', async () => {
      createComponent(mockQueryParams, mount);

      mock.onGet(configVariablesPath).reply(httpStatusCodes.OK, {
        [mockYmlKey]: {
          value: mockYmlMultiLineValue,
          description: mockYmlDesc,
        },
      });

      await waitForPromises();

      expect(findValueInputs().at(0).element.value).toBe(mockYmlMultiLineValue);
    });

    describe('with description', () => {
      beforeEach(async () => {
        createComponent(mockQueryParams, mount);

        mock.onGet(configVariablesPath).reply(httpStatusCodes.OK, {
          [mockYmlKey]: {
            value: mockYmlValue,
            description: mockYmlDesc,
          },
        });

        await waitForPromises();
      });

      it('displays all the variables', async () => {
        expect(findVariableRows()).toHaveLength(4);
      });

      it('displays a variable from yml', () => {
        expect(findKeyInputs().at(0).element.value).toBe(mockYmlKey);
        expect(findValueInputs().at(0).element.value).toBe(mockYmlValue);
      });

      it('displays a variable from provided query params', () => {
        expect(findKeyInputs().at(1).element.value).toBe('test_var');
        expect(findValueInputs().at(1).element.value).toBe('test_var_val');
      });

      it('adds a description to the first variable from yml', () => {
        expect(findVariableRows().at(0).text()).toContain(mockYmlDesc);
      });

      it('removes the description when a variable key changes', async () => {
        findKeyInputs().at(0).element.value = 'yml_var_modified';
        findKeyInputs().at(0).trigger('change');

        await wrapper.vm.$nextTick();

        expect(findVariableRows().at(0).text()).not.toContain(mockYmlDesc);
      });
    });

    describe('without description', () => {
      beforeEach(async () => {
        createComponent(mockQueryParams, mount);

        mock.onGet(configVariablesPath).reply(httpStatusCodes.OK, {
          [mockYmlKey]: {
            value: mockYmlValue,
            description: null,
          },
        });

        await waitForPromises();
      });

      it('displays all the variables', async () => {
        expect(findVariableRows()).toHaveLength(3);
      });
    });
  });

  describe('Form errors and warnings', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('when the refs cannot be loaded', () => {
      beforeEach(() => {
        mock
          .onGet(projectRefsEndpoint, { params: { search: '' } })
          .reply(httpStatusCodes.INTERNAL_SERVER_ERROR);

        findRefsDropdown().vm.$emit('loadingError');
      });

      it('shows both an error alert', () => {
        expect(findErrorAlert().exists()).toBe(true);
        expect(findWarningAlert().exists()).toBe(false);
      });
    });

    describe('when the error response can be handled', () => {
      beforeEach(async () => {
        mock.onPost(pipelinesPath).reply(httpStatusCodes.BAD_REQUEST, mockError);

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
        expect(wrapper.findComponent(CreditCardValidationRequiredAlert).exists()).toBe(false);
      });

      describe('when the error response is credit card validation required', () => {
        beforeEach(async () => {
          mock
            .onPost(pipelinesPath)
            .reply(httpStatusCodes.BAD_REQUEST, mockCreditCardValidationRequiredError);

          window.gon = {
            subscriptions_url: TEST_HOST,
            payment_form_url: TEST_HOST,
          };

          findForm().vm.$emit('submit', dummySubmitEvent);

          await waitForPromises();
        });

        it('shows credit card validation required alert', () => {
          expect(findErrorAlert().exists()).toBe(false);
          expect(wrapper.findComponent(CreditCardValidationRequiredAlert).exists()).toBe(true);
        });
      });
    });

    describe('when the error response cannot be handled', () => {
      beforeEach(async () => {
        mock
          .onPost(pipelinesPath)
          .reply(httpStatusCodes.INTERNAL_SERVER_ERROR, 'something went wrong');

        findForm().vm.$emit('submit', dummySubmitEvent);

        await waitForPromises();
      });

      it('re-enables the submit button', () => {
        expect(findSubmitButton().props('disabled')).toBe(false);
      });
    });
  });
});
