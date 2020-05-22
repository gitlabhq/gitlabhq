import { createStore } from '~/monitoring/stores';

describe('Monitoring Store Index', () => {
  it('creates store with a `monitoringDashboard` namespace', () => {
    expect(createStore().state).toEqual({
      monitoringDashboard: expect.any(Object),
    });
  });

  it('creates store with initial values', () => {
    const defaults = {
      deploymentsEndpoint: '/mock/deployments',
      dashboardEndpoint: '/mock/dashboard',
      dashboardsEndpoint: '/mock/dashboards',
    };

    const { state } = createStore(defaults);

    expect(state).toEqual({
      monitoringDashboard: expect.objectContaining(defaults),
    });
  });
});
