import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import AlertWidgetForm from '~/monitoring/components/alert_widget_form.vue';
import ModalStub from '../stubs/modal_stub';

describe('AlertWidgetForm', () => {
  let wrapper;

  const metricId = '8';
  const alertPath = 'alert';
  const relevantQueries = [{ metricId, alert_path: alertPath, label: 'alert-label' }];
  const dataTrackingOptions = {
    create: { action: 'click_button', label: 'create_alert' },
    delete: { action: 'click_button', label: 'delete_alert' },
    update: { action: 'click_button', label: 'update_alert' },
  };

  const defaultProps = {
    disabled: false,
    relevantQueries,
    modalId: 'alert-modal-1',
  };

  const propsWithAlertData = {
    ...defaultProps,
    alertsToManage: {
      alert: { alert_path: alertPath, operator: '<', threshold: 5, metricId },
    },
    configuredAlert: metricId,
  };

  function createComponent(props = {}) {
    const propsData = {
      ...defaultProps,
      ...props,
    };

    wrapper = shallowMount(AlertWidgetForm, {
      propsData,
      stubs: {
        GlModal: ModalStub,
      },
    });
  }

  const modal = () => wrapper.find(ModalStub);
  const modalTitle = () => modal().attributes('title');
  const submitButton = () => modal().find(GlLink);
  const submitButtonTrackingOpts = () =>
    JSON.parse(submitButton().attributes('data-tracking-options'));
  const e = {
    preventDefault: jest.fn(),
  };

  beforeEach(() => {
    e.preventDefault.mockReset();
  });

  afterEach(() => {
    if (wrapper) wrapper.destroy();
  });

  it('disables the form when disabled prop is set', () => {
    createComponent({ disabled: true });

    expect(modal().attributes('ok-disabled')).toBe('true');
  });

  it('disables the form if no query is selected', () => {
    createComponent();

    expect(modal().attributes('ok-disabled')).toBe('true');
  });

  it('shows correct title and button text', () => {
    expect(modalTitle()).toBe('Add alert');
    expect(submitButton().text()).toBe('Add');
  });

  it('sets tracking options for create alert', () => {
    expect(submitButtonTrackingOpts()).toEqual(dataTrackingOptions.create);
  });

  it('emits a "create" event when form submitted without existing alert', () => {
    createComponent();

    wrapper.vm.selectQuery('9');
    wrapper.setData({
      threshold: 900,
    });

    wrapper.vm.handleSubmit(e);

    expect(wrapper.emitted().create[0]).toEqual([
      {
        alert: undefined,
        operator: '>',
        threshold: 900,
        prometheus_metric_id: '9',
      },
    ]);
    expect(e.preventDefault).toHaveBeenCalledTimes(1);
  });

  it('resets form when modal is dismissed (hidden)', () => {
    createComponent();

    wrapper.vm.selectQuery('9');
    wrapper.vm.selectQuery('>');
    wrapper.setData({
      threshold: 800,
    });

    modal().vm.$emit('hidden');

    expect(wrapper.vm.selectedAlert).toEqual({});
    expect(wrapper.vm.operator).toBe(null);
    expect(wrapper.vm.threshold).toBe(null);
    expect(wrapper.vm.prometheusMetricId).toBe(null);
  });

  it('sets selectedAlert to the provided configuredAlert on modal show', () => {
    createComponent(propsWithAlertData);

    modal().vm.$emit('shown');

    expect(wrapper.vm.selectedAlert).toEqual(propsWithAlertData.alertsToManage[alertPath]);
  });

  describe('with existing alert', () => {
    beforeEach(() => {
      createComponent(propsWithAlertData);

      wrapper.vm.selectQuery(metricId);
    });

    it('sets tracking options for delete alert', () => {
      expect(submitButtonTrackingOpts()).toEqual(dataTrackingOptions.delete);
    });

    it('updates button text', () => {
      expect(modalTitle()).toBe('Edit alert');
      expect(submitButton().text()).toBe('Delete');
    });

    it('emits "delete" event when form values unchanged', () => {
      wrapper.vm.handleSubmit(e);

      expect(wrapper.emitted().delete[0]).toEqual([
        {
          alert: 'alert',
          operator: '<',
          threshold: 5,
          prometheus_metric_id: '8',
        },
      ]);
      expect(e.preventDefault).toHaveBeenCalledTimes(1);
    });

    it('emits "update" event when form changed', () => {
      wrapper.setData({
        threshold: 11,
      });

      wrapper.vm.handleSubmit(e);

      expect(wrapper.emitted().update[0]).toEqual([
        {
          alert: 'alert',
          operator: '<',
          threshold: 11,
          prometheus_metric_id: '8',
        },
      ]);
      expect(e.preventDefault).toHaveBeenCalledTimes(1);
    });

    it('sets tracking options for update alert', () => {
      wrapper.setData({
        threshold: 11,
      });

      return wrapper.vm.$nextTick(() => {
        expect(submitButtonTrackingOpts()).toEqual(dataTrackingOptions.update);
      });
    });
  });
});
