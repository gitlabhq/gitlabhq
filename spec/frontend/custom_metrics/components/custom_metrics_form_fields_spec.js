import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import CustomMetricsFormFields from '~/custom_metrics/components/custom_metrics_form_fields.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('custom metrics form fields component', () => {
  let wrapper;
  let mockAxios;

  const getNamedInput = (name) => wrapper.element.querySelector(`input[name="${name}"]`);
  const validateQueryPath = `${TEST_HOST}/mock/path`;
  const validQueryResponse = { success: true, query: { valid: true, error: '' } };
  const csrfToken = 'mockToken';
  const formOperation = 'post';
  const makeFormData = (data = {}) => ({
    formData: {
      title: '',
      yLabel: '',
      query: '',
      unit: '',
      group: '',
      legend: '',
      ...data,
    },
  });
  const mountComponent = (props) => {
    wrapper = mount(CustomMetricsFormFields, {
      propsData: {
        formOperation,
        validateQueryPath,
        ...props,
      },
      csrfToken,
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    mockAxios.restore();
  });

  it('checks form validity', async () => {
    mockAxios.onPost(validateQueryPath).reply(HTTP_STATUS_OK, validQueryResponse);
    mountComponent({
      metricPersisted: true,
      ...makeFormData({
        title: 'title-old',
        yLabel: 'yLabel',
        unit: 'unit',
        group: 'group',
      }),
    });

    wrapper.find(`input[name="prometheus_metric[query]"]`).setValue('query');
    await axios.waitForAll();

    expect(wrapper.emitted('formValidation')).toStrictEqual([[true]]);
  });

  describe('hidden inputs', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('specifies form operation _method', () => {
      expect(getNamedInput('_method', 'input').value).toBe('post');
    });

    it('specifies authenticity token', () => {
      expect(getNamedInput('authenticity_token', 'input').value).toBe(csrfToken);
    });
  });

  describe('name input', () => {
    const name = 'prometheus_metric[title]';

    it('is empty by default', () => {
      mountComponent();

      expect(getNamedInput(name).value).toBe('');
    });

    it('receives a persisted value', () => {
      const title = 'mockTitle';
      mountComponent(makeFormData({ title }));

      expect(getNamedInput(name).value).toBe(title);
    });
  });

  describe('group input', () => {
    it('has a default value', () => {
      mountComponent();

      expect(getNamedInput('prometheus_metric[group]', 'glformradiogroup-stub').value).toBe(
        'business',
      );
    });
  });

  describe('query input', () => {
    const queryInputName = 'prometheus_metric[query]';

    it('is empty by default', () => {
      mountComponent();

      expect(getNamedInput(queryInputName).value).toBe('');
    });

    it('receives and validates a persisted value', () => {
      const query = 'persistedQuery';
      jest.spyOn(axios, 'post');

      mountComponent({ metricPersisted: true, ...makeFormData({ query }) });

      expect(axios.post).toHaveBeenCalledWith(
        validateQueryPath,
        { query },
        expect.objectContaining({ cancelToken: expect.anything() }),
      );
      expect(getNamedInput(queryInputName).value).toBe(query);
      jest.runAllTimers();
    });

    it('checks validity on user input', async () => {
      const query = 'changedQuery';
      mountComponent();

      expect(mockAxios.history.post).toHaveLength(0);
      const queryInput = wrapper.find(`input[name="${queryInputName}"]`);
      queryInput.setValue(query);

      await axios.waitForAll();
      expect(mockAxios.history.post).toHaveLength(1);
    });

    describe('when query validation is in flight', () => {
      beforeEach(() => {
        mountComponent({ metricPersisted: true, ...makeFormData({ query: 'validQuery' }) });
        mockAxios.onPost(validateQueryPath).reply(HTTP_STATUS_OK, validQueryResponse);
      });

      it('expect loading message to display', async () => {
        const queryInput = wrapper.find(`input[name="${queryInputName}"]`);
        queryInput.setValue('query');
        await nextTick();

        expect(wrapper.text()).toContain('Validating query');
      });

      it('expect loading message to disappear', async () => {
        const queryInput = wrapper.find(`input[name="${queryInputName}"]`);
        queryInput.setValue('query');

        await axios.waitForAll();
        expect(wrapper.text()).not.toContain('Validating query');
      });
    });

    describe('when query is invalid', () => {
      const errorMessage = 'mockErrorMessage';
      const invalidQueryResponse = { success: true, query: { valid: false, error: errorMessage } };

      beforeEach(() => {
        mockAxios.onPost(validateQueryPath).reply(HTTP_STATUS_OK, invalidQueryResponse);
        mountComponent({ metricPersisted: true, ...makeFormData({ query: 'invalidQuery' }) });
        return axios.waitForAll();
      });

      it('shows invalid query message', () => {
        expect(wrapper.text()).toContain(errorMessage);
      });
    });

    describe('when query is valid', () => {
      beforeEach(() => {
        mockAxios.onPost(validateQueryPath).reply(HTTP_STATUS_OK, validQueryResponse);
        mountComponent({ metricPersisted: true, ...makeFormData({ query: 'validQuery' }) });
      });

      it('shows valid query message', async () => {
        await axios.waitForAll();

        expect(wrapper.text()).toContain('PromQL query is valid');
      });
    });
  });

  describe('yLabel input', () => {
    const name = 'prometheus_metric[y_label]';

    it('is empty by default', () => {
      mountComponent();

      expect(getNamedInput(name).value).toBe('');
    });

    it('receives a persisted value', () => {
      const yLabel = 'mockYLabel';
      mountComponent(makeFormData({ yLabel }));

      expect(getNamedInput(name).value).toBe(yLabel);
    });
  });

  describe('unit input', () => {
    const name = 'prometheus_metric[unit]';

    it('is empty by default', () => {
      mountComponent();

      expect(getNamedInput(name).value).toBe('');
    });

    it('receives a persisted value', () => {
      const unit = 'mockUnit';
      mountComponent(makeFormData({ unit }));

      expect(getNamedInput(name).value).toBe(unit);
    });
  });

  describe('legend input', () => {
    const name = 'prometheus_metric[legend]';

    it('is empty by default', () => {
      mountComponent();

      expect(getNamedInput(name).value).toBe('');
    });

    it('receives a persisted value', () => {
      const legend = 'mockLegend';
      mountComponent(makeFormData({ legend }));

      expect(getNamedInput(name).value).toBe(legend);
    });
  });
});
