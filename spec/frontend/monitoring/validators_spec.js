import { alertsValidator, queriesValidator } from '~/monitoring/validators';

describe('alertsValidator', () => {
  const validAlert = {
    alert_path: 'my/alert.json',
    operator: '<',
    threshold: 5,
    metricId: '8',
  };
  it('requires all alerts to have an alert path', () => {
    const { operator, threshold, metricId } = validAlert;
    const input = {
      [validAlert.alert_path]: {
        operator,
        threshold,
        metricId,
      },
    };
    expect(alertsValidator(input)).toEqual(false);
  });
  it('requires that the object key matches the alert path', () => {
    const input = {
      undefined: validAlert,
    };
    expect(alertsValidator(input)).toEqual(false);
  });
  it('requires all alerts to have a metric id', () => {
    const input = {
      [validAlert.alert_path]: { ...validAlert, metricId: undefined },
    };
    expect(alertsValidator(input)).toEqual(false);
  });
  it('requires the metricId to be a string', () => {
    const input = {
      [validAlert.alert_path]: { ...validAlert, metricId: 8 },
    };
    expect(alertsValidator(input)).toEqual(false);
  });
  it('requires all alerts to have an operator', () => {
    const input = {
      [validAlert.alert_path]: { ...validAlert, operator: '' },
    };
    expect(alertsValidator(input)).toEqual(false);
  });
  it('requires all alerts to have an numeric threshold', () => {
    const input = {
      [validAlert.alert_path]: { ...validAlert, threshold: '60' },
    };
    expect(alertsValidator(input)).toEqual(false);
  });
  it('correctly identifies a valid alerts object', () => {
    const input = {
      [validAlert.alert_path]: validAlert,
    };
    expect(alertsValidator(input)).toEqual(true);
  });
});
describe('queriesValidator', () => {
  const validQuery = {
    metricId: '8',
    alert_path: 'alert',
    label: 'alert-label',
  };
  it('requires all alerts to have a metric id', () => {
    const input = [{ ...validQuery, metricId: undefined }];
    expect(queriesValidator(input)).toEqual(false);
  });
  it('requires the metricId to be a string', () => {
    const input = [{ ...validQuery, metricId: 8 }];
    expect(queriesValidator(input)).toEqual(false);
  });
  it('requires all queries to have a label', () => {
    const input = [{ ...validQuery, label: undefined }];
    expect(queriesValidator(input)).toEqual(false);
  });
  it('correctly identifies a valid queries array', () => {
    const input = [validQuery];
    expect(queriesValidator(input)).toEqual(true);
  });
});
