import { mount, shallowMount } from '@vue/test-utils';
import { GlDropdown, GlDropdownItem, GlForm, GlSprintf, GlLoadingIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import httpStatusCodes from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';
import PipelineNewForm from '~/pipeline_new/components/pipeline_new_form.vue';
import {
  mockBranches,
  mockTags,
  mockParams,
  mockPostParams,
  mockProjectId,
  mockError,
} from '../mock_data';
import { redirectTo } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  redirectTo: jest.fn(),
}));

const pipelinesPath = '/root/project/-/pipelines';
const configVariablesPath = '/root/project/-/pipelines/config_variables';
const postResponse = { id: 1 };

describe('Pipeline New Form', () => {
  let wrapper;
  let mock;

  const dummySubmitEvent = {
    preventDefault() {},
  };

  const findForm = () => wrapper.find(GlForm);
  const findDropdown = () => wrapper.find(GlDropdown);
  const findDropdownItems = () => wrapper.findAll(GlDropdownItem);
  const findVariableRows = () => wrapper.findAll('[data-testid="ci-variable-row"]');
  const findRemoveIcons = () => wrapper.findAll('[data-testid="remove-ci-variable-row"]');
  const findKeyInputs = () => wrapper.findAll('[data-testid="pipeline-form-ci-variable-key"]');
  const findValueInputs = () => wrapper.findAll('[data-testid="pipeline-form-ci-variable-value"]');
  const findErrorAlert = () => wrapper.find('[data-testid="run-pipeline-error-alert"]');
  const findWarningAlert = () => wrapper.find('[data-testid="run-pipeline-warning-alert"]');
  const findWarningAlertSummary = () => findWarningAlert().find(GlSprintf);
  const findWarnings = () => wrapper.findAll('[data-testid="run-pipeline-warning"]');
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const getExpectedPostParams = () => JSON.parse(mock.history.post[0].data);
  const changeRef = (i) => findDropdownItems().at(i).vm.$emit('click');

  const createComponent = (term = '', props = {}, method = shallowMount) => {
    wrapper = method(PipelineNewForm, {
      propsData: {
        projectId: mockProjectId,
        pipelinesPath,
        configVariablesPath,
        branches: mockBranches,
        tags: mockTags,
        defaultBranch: 'master',
        settingsLink: '',
        maxWarnings: 25,
        ...props,
      },
      data() {
        return {
          searchTerm: term,
        };
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(configVariablesPath).reply(httpStatusCodes.OK, {});
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    mock.restore();
  });

  describe('Dropdown with branches and tags', () => {
    beforeEach(() => {
      mock.onPost(pipelinesPath).reply(httpStatusCodes.OK, postResponse);
    });

    it('displays dropdown with all branches and tags', () => {
      const refLength = mockBranches.length + mockTags.length;

      createComponent();

      expect(findDropdownItems()).toHaveLength(refLength);
    });

    it('when user enters search term the list is filtered', () => {
      createComponent('master');

      expect(findDropdownItems()).toHaveLength(1);
      expect(findDropdownItems().at(0).text()).toBe('master');
    });
  });

  describe('Form', () => {
    beforeEach(async () => {
      createComponent('', mockParams, mount);

      mock.onPost(pipelinesPath).reply(httpStatusCodes.OK, postResponse);

      await waitForPromises();
    });

    it('displays the correct values for the provided query params', async () => {
      expect(findDropdown().props('text')).toBe('tag-1');
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
      mock.onPost(pipelinesPath).reply(httpStatusCodes.OK, postResponse);

      await waitForPromises();
    });
    it('creates pipeline with full ref and variables', async () => {
      createComponent();

      changeRef(0);

      findForm().vm.$emit('submit', dummySubmitEvent);

      await waitForPromises();

      expect(getExpectedPostParams().ref).toEqual(wrapper.vm.$data.refValue.fullName);
      expect(redirectTo).toHaveBeenCalledWith(`${pipelinesPath}/${postResponse.id}`);
    });
    it('creates a pipeline with short ref and variables', async () => {
      // query params are used
      createComponent('', mockParams);

      await waitForPromises();

      findForm().vm.$emit('submit', dummySubmitEvent);

      await waitForPromises();

      expect(getExpectedPostParams()).toEqual(mockPostParams);
      expect(redirectTo).toHaveBeenCalledWith(`${pipelinesPath}/${postResponse.id}`);
    });
  });

  describe('When the ref has been changed', () => {
    beforeEach(async () => {
      createComponent('', {}, mount);

      await waitForPromises();
    });
    it('variables persist between ref changes', async () => {
      changeRef(0); // change to master

      await waitForPromises();

      const masterInput = findKeyInputs().at(0);
      masterInput.element.value = 'build_var';
      masterInput.trigger('change');

      await wrapper.vm.$nextTick();

      changeRef(1); // change to branch-1

      await waitForPromises();

      const branchOneInput = findKeyInputs().at(0);
      branchOneInput.element.value = 'deploy_var';
      branchOneInput.trigger('change');

      await wrapper.vm.$nextTick();

      changeRef(0); // change back to master

      await waitForPromises();

      expect(findKeyInputs().at(0).element.value).toBe('build_var');
      expect(findVariableRows().length).toBe(2);

      changeRef(1); // change back to branch-1

      await waitForPromises();

      expect(findKeyInputs().at(0).element.value).toBe('deploy_var');
      expect(findVariableRows().length).toBe(2);
    });
  });

  describe('when yml defines a variable', () => {
    const mockYmlKey = 'yml_var';
    const mockYmlValue = 'yml_var_val';
    const mockYmlDesc = 'A var from yml.';

    it('loading icon is shown when content is requested and hidden when received', async () => {
      createComponent('', mockParams, mount);

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

    describe('with description', () => {
      beforeEach(async () => {
        createComponent('', mockParams, mount);

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
        createComponent('', mockParams, mount);

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

      mock.onPost(pipelinesPath).reply(httpStatusCodes.BAD_REQUEST, mockError);

      findForm().vm.$emit('submit', dummySubmitEvent);

      return waitForPromises();
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
  });
});
