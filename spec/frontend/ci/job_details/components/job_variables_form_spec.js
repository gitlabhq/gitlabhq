import { GlSprintf, GlLink } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { createAlert } from '~/alert';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { JOB_GRAPHQL_ERRORS } from '~/ci/constants';
import waitForPromises from 'helpers/wait_for_promises';
import JobVariablesForm from '~/ci/job_details/components/job_variables_form.vue';
import getJobQuery from '~/ci/job_details/graphql/queries/get_job.query.graphql';
import { mockFullPath, mockId, mockJobResponse, mockJobWithVariablesResponse } from '../mock_data';

jest.mock('~/alert');
Vue.use(VueApollo);

const defaultProvide = {
  projectPath: mockFullPath,
};
const defaultProps = {
  jobId: mockId,
};

describe('Job Variables Form', () => {
  let wrapper;
  let mockApollo;

  const getJobQueryResponseHandlerWithVariables = jest.fn().mockResolvedValue(mockJobResponse);

  const defaultHandlers = {
    getJobQueryResponseHandlerWithVariables,
  };

  const createComponent = ({ handlers = defaultHandlers } = {}) => {
    mockApollo = createMockApollo([
      [getJobQuery, handlers.getJobQueryResponseHandlerWithVariables],
    ]);

    const options = {
      apolloProvider: mockApollo,
    };

    wrapper = mountExtended(JobVariablesForm, {
      propsData: {
        ...defaultProps,
      },
      provide: {
        ...defaultProvide,
      },
      ...options,
    });

    return waitForPromises();
  };

  const findHelpText = () => wrapper.findComponent(GlSprintf);
  const findHelpLink = () => wrapper.findComponent(GlLink);
  const findDeleteVarBtn = () => wrapper.findByTestId('delete-variable-btn');
  const findAllDeleteVarBtns = () => wrapper.findAllByTestId('delete-variable-btn');
  const findDeleteVarBtnPlaceholder = () => wrapper.findByTestId('delete-variable-btn-placeholder');
  const findCiVariableKey = () => wrapper.findByTestId('ci-variable-key');
  const findAllCiVariableKeys = () => wrapper.findAllByTestId('ci-variable-key');
  const findCiVariableValue = () => wrapper.findByTestId('ci-variable-value');
  const findAllVariables = () => wrapper.findAllByTestId('ci-variable-row');

  const setCiVariableKey = () => {
    findCiVariableKey().setValue('new key');
    findCiVariableKey().vm.$emit('change');
    nextTick();
  };

  const setCiVariableKeyByPosition = (position, value) => {
    findAllCiVariableKeys().at(position).setValue(value);
    findAllCiVariableKeys().at(position).vm.$emit('change');
    nextTick();
  };

  afterEach(() => {
    createAlert.mockClear();
  });

  describe('when page renders', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('renders help text with provided link', () => {
      expect(findHelpText().exists()).toBe(true);
      expect(findHelpLink().attributes('href')).toBe('/help/ci/variables/_index#for-a-project');
    });
  });

  describe('when query is unsuccessful', () => {
    beforeEach(async () => {
      await createComponent({
        handlers: {
          getJobQueryResponseHandlerWithVariables: jest.fn().mockRejectedValue({}),
        },
      });
    });

    it('shows an alert with error', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: JOB_GRAPHQL_ERRORS.jobQueryErrorText,
      });
    });
  });

  describe('when job has variables', () => {
    beforeEach(async () => {
      await createComponent({
        handlers: {
          getJobQueryResponseHandlerWithVariables: jest
            .fn()
            .mockResolvedValue(mockJobWithVariablesResponse),
        },
      });
    });

    it('sets job variables', () => {
      const queryKey = mockJobWithVariablesResponse.data.project.job.manualVariables.nodes[0].key;
      const queryValue =
        mockJobWithVariablesResponse.data.project.job.manualVariables.nodes[0].value;

      expect(findCiVariableKey().element.value).toBe(queryKey);
      expect(findCiVariableValue().element.value).toBe(queryValue);
    });
  });

  describe('updating variables in UI', () => {
    beforeEach(async () => {
      await createComponent({
        handlers: {
          getJobQueryResponseHandlerWithVariables: jest.fn().mockResolvedValue(mockJobResponse),
        },
      });
    });

    it('creates a new variable when user enters a new key value', async () => {
      expect(findAllVariables()).toHaveLength(1);

      await setCiVariableKey();

      expect(findAllVariables()).toHaveLength(2);
    });

    it('does not create extra empty variables', async () => {
      expect(findAllVariables()).toHaveLength(1);

      await setCiVariableKey();

      expect(findAllVariables()).toHaveLength(2);

      await setCiVariableKey();

      expect(findAllVariables()).toHaveLength(2);
    });

    it('removes the correct variable row', async () => {
      const variableKeyNameOne = 'key-one';
      const variableKeyNameThree = 'key-three';

      await setCiVariableKeyByPosition(0, variableKeyNameOne);

      await setCiVariableKeyByPosition(1, 'key-two');

      await setCiVariableKeyByPosition(2, variableKeyNameThree);

      expect(findAllVariables()).toHaveLength(4);

      await findAllDeleteVarBtns().at(1).trigger('click');

      expect(findAllVariables()).toHaveLength(3);

      expect(findAllCiVariableKeys().at(0).element.value).toBe(variableKeyNameOne);
      expect(findAllCiVariableKeys().at(1).element.value).toBe(variableKeyNameThree);
      expect(findAllCiVariableKeys().at(2).element.value).toBe('');
    });

    it('delete variable button should only show when there is more than one variable', async () => {
      expect(findDeleteVarBtn().exists()).toBe(false);

      await setCiVariableKey();

      expect(findDeleteVarBtn().exists()).toBe(true);
    });
  });

  describe('variable delete button placeholder', () => {
    beforeEach(async () => {
      await createComponent({
        handlers: {
          getJobQueryResponseHandlerWithVariables: jest.fn().mockResolvedValue(mockJobResponse),
        },
      });
    });

    it('delete variable button placeholder should only exist when a user cannot remove', () => {
      expect(findDeleteVarBtnPlaceholder().exists()).toBe(true);
    });

    it('does not show the placeholder button', () => {
      expect(findDeleteVarBtnPlaceholder().classes('gl-opacity-0')).toBe(true);
    });

    it('placeholder button will not delete the row on click', async () => {
      expect(findAllCiVariableKeys()).toHaveLength(1);
      expect(findDeleteVarBtnPlaceholder().exists()).toBe(true);

      await findDeleteVarBtnPlaceholder().trigger('click');

      expect(findAllCiVariableKeys()).toHaveLength(1);
      expect(findDeleteVarBtnPlaceholder().exists()).toBe(true);
    });
  });

  describe('emitting events', () => {
    beforeEach(async () => {
      await createComponent({
        handlers: {
          getJobQueryResponseHandlerWithVariables: jest.fn().mockResolvedValue(mockJobResponse),
        },
      });
    });

    it('emits update-variables event when data changes', async () => {
      const newVariable = { key: 'new key', value: 'test-value' };
      const emptyVariable = { key: '', value: '' };

      const initialEvent = wrapper.emitted('update-variables').at(0)[0];
      expect(initialEvent).toHaveLength(1);
      expect(initialEvent).toEqual(
        expect.arrayContaining([expect.objectContaining({ ...emptyVariable })]),
      );

      await setCiVariableKey();
      await findCiVariableValue().setValue(newVariable.value);

      const lastEvent = wrapper.emitted('update-variables').at(-1)[0];
      expect(lastEvent).toHaveLength(2);
      expect(lastEvent).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            ...newVariable,
          }),
          expect.objectContaining({ ...emptyVariable }),
        ]),
      );
    });
  });
});
