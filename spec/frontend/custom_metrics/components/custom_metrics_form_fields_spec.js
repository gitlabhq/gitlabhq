import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import CustomMetricsFormFields from '~/custom_metrics/components/custom_metrics_form_fields.vue';
import axios from '~/lib/utils/axios_utils';

const { CancelToken } = axios;

describe('custom metrics form fields component', () => {
  let component;
  let mockAxios;

  const getNamedInput = name => component.element.querySelector(`input[name="${name}"]`);
  const validateQueryPath = `${TEST_HOST}/mock/path`;
  const validQueryResponse = { data: { success: true, query: { valid: true, error: '' } } };
  const csrfToken = 'mockToken';
  const formOperation = 'post';
  const debouncedValidateQueryMock = jest.fn();
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
  const mountComponent = (props, methods = {}) => {
    component = mount(CustomMetricsFormFields, {
      propsData: {
        formOperation,
        validateQueryPath,
        ...props,
      },
      csrfToken,
      methods,
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    mockAxios.onPost(validateQueryPath).reply(validQueryResponse);
  });

  afterEach(() => {
    component.destroy();
    mockAxios.restore();
  });

  it('checks form validity', done => {
    mountComponent({
      metricPersisted: true,
      ...makeFormData({
        title: 'title',
        yLabel: 'yLabel',
        unit: 'unit',
        group: 'group',
      }),
    });

    component.vm.$nextTick(() => {
      expect(component.vm.formIsValid).toBe(false);
      done();
    });
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
    beforeEach(() => {
      mockAxios.onPost(validateQueryPath).reply(validQueryResponse);
    });

    it('is empty by default', () => {
      mountComponent();

      expect(getNamedInput(queryInputName).value).toBe('');
    });

    it('receives and validates a persisted value', () => {
      const query = 'persistedQuery';
      const axiosPost = jest.spyOn(axios, 'post');
      const source = CancelToken.source();
      mountComponent({ metricPersisted: true, ...makeFormData({ query }) });

      expect(axiosPost).toHaveBeenCalledWith(
        validateQueryPath,
        { query },
        { cancelToken: source.token },
      );
      expect(getNamedInput(queryInputName).value).toBe(query);
      jest.runAllTimers();
    });

    it('checks validity on user input', () => {
      const query = 'changedQuery';
      mountComponent(
        {},
        {
          debouncedValidateQuery: debouncedValidateQueryMock,
        },
      );
      const queryInput = component.find(`input[name="${queryInputName}"]`);
      queryInput.setValue(query);
      queryInput.trigger('input');

      expect(debouncedValidateQueryMock).toHaveBeenCalledWith(query);
    });

    describe('when query validation is in flight', () => {
      beforeEach(() => {
        mountComponent(
          { metricPersisted: true, ...makeFormData({ query: 'validQuery' }) },
          {
            requestValidation: jest.fn().mockImplementation(
              () =>
                new Promise(resolve =>
                  setTimeout(() => {
                    resolve(validQueryResponse);
                  }, 4000),
                ),
            ),
          },
        );
      });

      afterEach(() => {
        jest.clearAllTimers();
      });

      it('expect queryValidateInFlight is in flight', done => {
        const queryInput = component.find(`input[name="${queryInputName}"]`);
        queryInput.setValue('query');
        queryInput.trigger('input');

        component.vm.$nextTick(() => {
          expect(component.vm.queryValidateInFlight).toBe(true);
          jest.runOnlyPendingTimers();
          waitForPromises()
            .then(() => {
              component.vm.$nextTick(() => {
                expect(component.vm.queryValidateInFlight).toBe(false);
                expect(component.vm.queryIsValid).toBe(true);
                done();
              });
            })
            .catch(done.fail);
        });
      });

      it('expect loading message to display', done => {
        const queryInput = component.find(`input[name="${queryInputName}"]`);
        queryInput.setValue('query');
        queryInput.trigger('input');
        component.vm.$nextTick(() => {
          expect(component.text()).toContain('Validating query');
          jest.runOnlyPendingTimers();
          done();
        });
      });

      it('expect loading message to disappear', done => {
        const queryInput = component.find(`input[name="${queryInputName}"]`);
        queryInput.setValue('query');
        queryInput.trigger('input');
        component.vm.$nextTick(() => {
          jest.runOnlyPendingTimers();
          waitForPromises()
            .then(() => {
              component.vm.$nextTick(() => {
                expect(component.vm.queryValidateInFlight).toBe(false);
                expect(component.vm.queryIsValid).toBe(true);
                expect(component.vm.errorMessage).toBe('');
                done();
              });
            })
            .catch(done.fail);
        });
      });
    });

    describe('when query is invalid', () => {
      const errorMessage = 'mockErrorMessage';
      const invalidQueryResponse = {
        data: { success: true, query: { valid: false, error: errorMessage } },
      };

      beforeEach(() => {
        mountComponent(
          { metricPersisted: true, ...makeFormData({ query: 'invalidQuery' }) },
          {
            requestValidation: jest
              .fn()
              .mockImplementation(() => Promise.resolve(invalidQueryResponse)),
          },
        );
      });

      it('sets queryIsValid to false', done => {
        component.vm.$nextTick(() => {
          expect(component.vm.queryValidateInFlight).toBe(false);
          expect(component.vm.queryIsValid).toBe(false);
          done();
        });
      });

      it('shows invalid query message', done => {
        component.vm.$nextTick(() => {
          expect(component.text()).toContain(errorMessage);
          done();
        });
      });
    });

    describe('when query is valid', () => {
      beforeEach(() => {
        mountComponent(
          { metricPersisted: true, ...makeFormData({ query: 'validQuery' }) },
          {
            requestValidation: jest
              .fn()
              .mockImplementation(() => Promise.resolve(validQueryResponse)),
          },
        );
      });

      it('sets queryIsValid to true when query is valid', done => {
        component.vm.$nextTick(() => {
          expect(component.vm.queryIsValid).toBe(true);
          done();
        });
      });

      it('shows valid query message', () => {
        expect(component.text()).toContain('PromQL query is valid');
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
