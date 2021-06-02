import { GlLoadingIcon, GlTooltip, GlSprintf, GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import AlertWidget from '~/monitoring/components/alert_widget.vue';

const mockReadAlert = jest.fn();
const mockCreateAlert = jest.fn();
const mockUpdateAlert = jest.fn();
const mockDeleteAlert = jest.fn();

jest.mock('~/flash');
jest.mock(
  '~/monitoring/services/alerts_service',
  () =>
    function AlertsServiceMock() {
      return {
        readAlert: mockReadAlert,
        createAlert: mockCreateAlert,
        updateAlert: mockUpdateAlert,
        deleteAlert: mockDeleteAlert,
      };
    },
);

describe('AlertWidget', () => {
  let wrapper;

  const nonFiringAlertResult = [
    {
      values: [
        [0, 1],
        [1, 42],
        [2, 41],
      ],
    },
  ];
  const firingAlertResult = [
    {
      values: [
        [0, 42],
        [1, 43],
        [2, 44],
      ],
    },
  ];
  const metricId = '5';
  const alertPath = 'my/alert.json';

  const relevantQueries = [
    {
      metricId,
      label: 'alert-label',
      alert_path: alertPath,
      result: nonFiringAlertResult,
    },
  ];

  const firingRelevantQueries = [
    {
      metricId,
      label: 'alert-label',
      alert_path: alertPath,
      result: firingAlertResult,
    },
  ];

  const defaultProps = {
    alertsEndpoint: '',
    relevantQueries,
    alertsToManage: {},
    modalId: 'alert-modal-1',
  };

  const propsWithAlert = {
    relevantQueries,
  };

  const propsWithAlertData = {
    relevantQueries,
    alertsToManage: {
      [alertPath]: { operator: '>', threshold: 42, alert_path: alertPath, metricId },
    },
  };

  const createComponent = (propsData) => {
    wrapper = shallowMount(AlertWidget, {
      stubs: { GlTooltip, GlSprintf },
      propsData: {
        ...defaultProps,
        ...propsData,
      },
    });
  };
  const hasLoadingIcon = () => wrapper.find(GlLoadingIcon).exists();
  const findWidgetForm = () => wrapper.find({ ref: 'widgetForm' });
  const findAlertErrorMessage = () => wrapper.find({ ref: 'alertErrorMessage' });
  const findCurrentSettingsText = () =>
    wrapper.find({ ref: 'alertCurrentSetting' }).text().replace(/\s\s+/g, ' ');
  const findBadge = () => wrapper.find(GlBadge);
  const findTooltip = () => wrapper.find(GlTooltip);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('displays a loading spinner and disables form when fetching alerts', () => {
    let resolveReadAlert;
    mockReadAlert.mockReturnValue(
      new Promise((resolve) => {
        resolveReadAlert = resolve;
      }),
    );
    createComponent(defaultProps);
    return wrapper.vm
      .$nextTick()
      .then(() => {
        expect(hasLoadingIcon()).toBe(true);
        expect(findWidgetForm().props('disabled')).toBe(true);

        resolveReadAlert({ operator: '==', threshold: 42 });
      })
      .then(() => waitForPromises())
      .then(() => {
        expect(hasLoadingIcon()).toBe(false);
        expect(findWidgetForm().props('disabled')).toBe(false);
      });
  });

  it('does not render loading spinner if showLoadingState is false', () => {
    let resolveReadAlert;
    mockReadAlert.mockReturnValue(
      new Promise((resolve) => {
        resolveReadAlert = resolve;
      }),
    );
    createComponent({
      ...defaultProps,
      showLoadingState: false,
    });
    return wrapper.vm
      .$nextTick()
      .then(() => {
        expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);

        resolveReadAlert({ operator: '==', threshold: 42 });
      })
      .then(() => waitForPromises())
      .then(() => {
        expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
      });
  });

  it('displays an error message when fetch fails', () => {
    mockReadAlert.mockRejectedValue();
    createComponent(propsWithAlert);
    expect(hasLoadingIcon()).toBe(true);

    return waitForPromises().then(() => {
      expect(createFlash).toHaveBeenCalled();
      expect(hasLoadingIcon()).toBe(false);
    });
  });

  describe('Alert not firing', () => {
    it('displays a warning icon and matches snapshot', () => {
      mockReadAlert.mockResolvedValue({ operator: '>', threshold: 42 });
      createComponent(propsWithAlertData);

      return waitForPromises().then(() => {
        expect(findBadge().element).toMatchSnapshot();
      });
    });

    it('displays an alert summary when there is a single alert', () => {
      mockReadAlert.mockResolvedValue({ operator: '>', threshold: 42 });
      createComponent(propsWithAlertData);
      return waitForPromises().then(() => {
        expect(findCurrentSettingsText()).toEqual('alert-label > 42');
      });
    });

    it('displays a combined alert summary when there are multiple alerts', () => {
      mockReadAlert.mockResolvedValue({ operator: '>', threshold: 42 });
      const propsWithManyAlerts = {
        relevantQueries: [
          ...relevantQueries,
          ...[
            {
              metricId: '6',
              alert_path: 'my/alert2.json',
              label: 'alert-label2',
              result: [{ values: [] }],
            },
          ],
        ],
        alertsToManage: {
          'my/alert.json': {
            operator: '>',
            threshold: 42,
            alert_path: alertPath,
            metricId,
          },
          'my/alert2.json': {
            operator: '==',
            threshold: 900,
            alert_path: 'my/alert2.json',
            metricId: '6',
          },
        },
      };
      createComponent(propsWithManyAlerts);
      return waitForPromises().then(() => {
        expect(findCurrentSettingsText()).toContain('2 alerts applied');
      });
    });
  });

  describe('Alert firing', () => {
    it('displays a warning icon and matches snapshot', () => {
      mockReadAlert.mockResolvedValue({ operator: '>', threshold: 42 });
      propsWithAlertData.relevantQueries = firingRelevantQueries;
      createComponent(propsWithAlertData);

      return waitForPromises().then(() => {
        expect(findBadge().element).toMatchSnapshot();
      });
    });

    it('displays an alert summary when there is a single alert', () => {
      mockReadAlert.mockResolvedValue({ operator: '>', threshold: 42 });
      propsWithAlertData.relevantQueries = firingRelevantQueries;
      createComponent(propsWithAlertData);
      return waitForPromises().then(() => {
        expect(findCurrentSettingsText()).toEqual('Firing: alert-label > 42');
      });
    });

    it('displays a combined alert summary when there are multiple alerts', () => {
      mockReadAlert.mockResolvedValue({ operator: '>', threshold: 42 });
      const propsWithManyAlerts = {
        relevantQueries: [
          ...firingRelevantQueries,
          ...[
            {
              metricId: '6',
              alert_path: 'my/alert2.json',
              label: 'alert-label2',
              result: [{ values: [] }],
            },
          ],
        ],
        alertsToManage: {
          'my/alert.json': {
            operator: '>',
            threshold: 42,
            alert_path: alertPath,
            metricId,
          },
          'my/alert2.json': {
            operator: '==',
            threshold: 900,
            alert_path: 'my/alert2.json',
            metricId: '6',
          },
        },
      };
      createComponent(propsWithManyAlerts);

      return waitForPromises().then(() => {
        expect(findCurrentSettingsText()).toContain('2 alerts applied, 1 firing');
      });
    });

    it('should display tooltip with thresholds summary', () => {
      mockReadAlert.mockResolvedValue({ operator: '>', threshold: 42 });
      const propsWithManyAlerts = {
        relevantQueries: [
          ...firingRelevantQueries,
          ...[
            {
              metricId: '6',
              alert_path: 'my/alert2.json',
              label: 'alert-label2',
              result: [{ values: [] }],
            },
          ],
        ],
        alertsToManage: {
          'my/alert.json': {
            operator: '>',
            threshold: 42,
            alert_path: alertPath,
            metricId,
          },
          'my/alert2.json': {
            operator: '==',
            threshold: 900,
            alert_path: 'my/alert2.json',
            metricId: '6',
          },
        },
      };
      createComponent(propsWithManyAlerts);

      return waitForPromises().then(() => {
        expect(findTooltip().text().replace(/\s\s+/g, ' ')).toEqual('Firing: alert-label > 42');
      });
    });
  });

  it('creates an alert with an appropriate handler', () => {
    const alertParams = {
      operator: '<',
      threshold: 4,
      prometheus_metric_id: '5',
    };
    mockReadAlert.mockResolvedValue({ operator: '>', threshold: 42 });
    const fakeAlertPath = 'foo/bar';
    mockCreateAlert.mockResolvedValue({ alert_path: fakeAlertPath, ...alertParams });
    createComponent({
      alertsToManage: {
        [fakeAlertPath]: {
          alert_path: fakeAlertPath,
          operator: '<',
          threshold: 4,
          prometheus_metric_id: '5',
          metricId: '5',
        },
      },
    });

    findWidgetForm().vm.$emit('create', alertParams);

    expect(mockCreateAlert).toHaveBeenCalledWith(alertParams);
  });

  it('updates an alert with an appropriate handler', () => {
    const alertParams = { operator: '<', threshold: 4, alert_path: alertPath };
    const newAlertParams = { operator: '==', threshold: 12 };
    mockReadAlert.mockResolvedValue(alertParams);
    mockUpdateAlert.mockResolvedValue({ ...alertParams, ...newAlertParams });
    createComponent({
      ...propsWithAlertData,
      alertsToManage: {
        [alertPath]: {
          alert_path: alertPath,
          operator: '==',
          threshold: 12,
          metricId: '5',
        },
      },
    });

    findWidgetForm().vm.$emit('update', {
      alert: alertPath,
      ...newAlertParams,
      prometheus_metric_id: '5',
    });

    expect(mockUpdateAlert).toHaveBeenCalledWith(alertPath, newAlertParams);
  });

  it('deletes an alert with an appropriate handler', () => {
    const alertParams = { alert_path: alertPath, operator: '>', threshold: 42 };
    mockReadAlert.mockResolvedValue(alertParams);
    mockDeleteAlert.mockResolvedValue({});
    createComponent({
      ...propsWithAlert,
      alertsToManage: {
        [alertPath]: {
          alert_path: alertPath,
          operator: '>',
          threshold: 42,
          metricId: '5',
        },
      },
    });

    findWidgetForm().vm.$emit('delete', { alert: alertPath });

    return wrapper.vm.$nextTick().then(() => {
      expect(mockDeleteAlert).toHaveBeenCalledWith(alertPath);
      expect(findAlertErrorMessage().exists()).toBe(false);
    });
  });

  describe('when delete fails', () => {
    beforeEach(() => {
      const alertParams = { alert_path: alertPath, operator: '>', threshold: 42 };
      mockReadAlert.mockResolvedValue(alertParams);
      mockDeleteAlert.mockRejectedValue();

      createComponent({
        ...propsWithAlert,
        alertsToManage: {
          [alertPath]: {
            alert_path: alertPath,
            operator: '>',
            threshold: 42,
            metricId: '5',
          },
        },
      });

      findWidgetForm().vm.$emit('delete', { alert: alertPath });
      return wrapper.vm.$nextTick();
    });

    it('shows error message', () => {
      expect(findAlertErrorMessage().text()).toEqual('Error deleting alert');
    });

    it('dismisses error message on cancel', () => {
      findWidgetForm().vm.$emit('cancel');

      return wrapper.vm.$nextTick().then(() => {
        expect(findAlertErrorMessage().exists()).toBe(false);
      });
    });
  });
});
