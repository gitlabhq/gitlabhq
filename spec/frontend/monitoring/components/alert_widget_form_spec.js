import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import INVALID_URL from '~/lib/utils/invalid_url';
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
      alert: {
        alert_path: alertPath,
        operator: '<',
        threshold: 5,
        metricId,
        runbookUrl: INVALID_URL,
      },
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
  const findRunbookField = () => modal().find('[data-testid="alertRunbookField"]');
  const findThresholdField = () => modal().find('[data-qa-selector="alert_threshold_field"]');
  const submitButtonTrackingOpts = () =>
    JSON.parse(submitButton().attributes('data-tracking-options'));
  const stubEvent = { preventDefault: jest.fn() };

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
    createComponent();

    expect(modalTitle()).toBe('Add alert');
    expect(submitButton().text()).toBe('Add');
  });

  it('sets tracking options for create alert', () => {
    createComponent();

    expect(submitButtonTrackingOpts()).toEqual(dataTrackingOptions.create);
  });

  it('emits a "create" event when form submitted without existing alert', async () => {
    createComponent(defaultProps);

    modal().vm.$emit('shown');

    findThresholdField().vm.$emit('input', 900);
    findRunbookField().vm.$emit('input', INVALID_URL);

    modal().vm.$emit('ok', stubEvent);

    expect(wrapper.emitted().create[0]).toEqual([
      {
        alert: undefined,
        operator: '>',
        threshold: 900,
        prometheus_metric_id: '8',
        runbookUrl: INVALID_URL,
      },
    ]);
  });

  it('resets form when modal is dismissed (hidden)', () => {
    createComponent(defaultProps);

    modal().vm.$emit('shown');

    findThresholdField().vm.$emit('input', 800);
    findRunbookField().vm.$emit('input', INVALID_URL);

    modal().vm.$emit('hidden');

    expect(wrapper.vm.selectedAlert).toEqual({});
    expect(wrapper.vm.operator).toBe(null);
    expect(wrapper.vm.threshold).toBe(null);
    expect(wrapper.vm.prometheusMetricId).toBe(null);
    expect(wrapper.vm.runbookUrl).toBe(null);
  });

  it('sets selectedAlert to the provided configuredAlert on modal show', () => {
    createComponent(propsWithAlertData);

    modal().vm.$emit('shown');

    expect(wrapper.vm.selectedAlert).toEqual(propsWithAlertData.alertsToManage[alertPath]);
  });

  it('sets selectedAlert to the first relevantQueries if there is only one option on modal show', () => {
    createComponent({
      ...propsWithAlertData,
      configuredAlert: '',
    });

    modal().vm.$emit('shown');

    expect(wrapper.vm.selectedAlert).toEqual(propsWithAlertData.alertsToManage[alertPath]);
  });

  it('does not set selectedAlert to the first relevantQueries if there is more than one option on modal show', () => {
    createComponent({
      relevantQueries: [
        {
          metricId: '8',
          alertPath: 'alert',
          label: 'alert-label',
        },
        {
          metricId: '9',
          alertPath: 'alert',
          label: 'alert-label',
        },
      ],
    });

    modal().vm.$emit('shown');

    expect(wrapper.vm.selectedAlert).toEqual({});
  });

  describe('with existing alert', () => {
    beforeEach(() => {
      createComponent(propsWithAlertData);

      modal().vm.$emit('shown');
    });

    it('sets tracking options for delete alert', () => {
      expect(submitButtonTrackingOpts()).toEqual(dataTrackingOptions.delete);
    });

    it('updates button text', () => {
      expect(modalTitle()).toBe('Edit alert');
      expect(submitButton().text()).toBe('Delete');
    });

    it('emits "delete" event when form values unchanged', () => {
      modal().vm.$emit('ok', stubEvent);

      expect(wrapper.emitted().delete[0]).toEqual([
        {
          alert: 'alert',
          operator: '<',
          threshold: 5,
          prometheus_metric_id: '8',
          runbookUrl: INVALID_URL,
        },
      ]);
    });
  });

  it('emits "update" event when form changed', () => {
    const updatedRunbookUrl = `${INVALID_URL}/test`;

    createComponent(propsWithAlertData);

    modal().vm.$emit('shown');

    findRunbookField().vm.$emit('input', updatedRunbookUrl);
    findThresholdField().vm.$emit('input', 11);

    modal().vm.$emit('ok', stubEvent);

    expect(wrapper.emitted().update[0]).toEqual([
      {
        alert: 'alert',
        operator: '<',
        threshold: 11,
        prometheus_metric_id: '8',
        runbookUrl: updatedRunbookUrl,
      },
    ]);
  });

  it('sets tracking options for update alert', async () => {
    createComponent(propsWithAlertData);

    modal().vm.$emit('shown');

    findThresholdField().vm.$emit('input', 11);

    await wrapper.vm.$nextTick();

    expect(submitButtonTrackingOpts()).toEqual(dataTrackingOptions.update);
  });

  describe('alert runbooks', () => {
    it('shows the runbook field', () => {
      createComponent();

      expect(findRunbookField().exists()).toBe(true);
    });
  });
});
