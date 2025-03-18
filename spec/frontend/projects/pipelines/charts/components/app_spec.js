import { GlTabs } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import App from '~/projects/pipelines/charts/components/app.vue';

import PipelinesDashboard from '~/projects/pipelines/charts/components/pipelines_dashboard.vue';
import PipelinesDashboardClickhouse from '~/projects/pipelines/charts/components/pipelines_dashboard_clickhouse.vue';

describe('ProjectsPipelinesChartsApp', () => {
  let wrapper;

  const createWrapper = ({ provide, ...options } = {}) => {
    wrapper = shallowMount(App, {
      provide: {
        ...provide,
      },
      ...options,
    });
  };

  const findGlTabs = () => wrapper.findComponent(GlTabs);

  const findPipelinesDashboard = () => wrapper.findComponent(PipelinesDashboard);
  const findPipelinesDashboardClickhouse = () =>
    wrapper.findComponent(PipelinesDashboardClickhouse);

  describe('when showing only pipelines dashboard', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('does not render tabs', () => {
      // tabs are only shown in EE
      expect(findGlTabs().exists()).toBe(false);
    });

    it('shows pipelines dashboard', () => {
      expect(wrapper.findComponent(PipelinesDashboard).exists()).toBe(true);
    });
  });

  describe('ci_improved_project_pipeline_analytics feature flag', () => {
    describe.each`
      status   | finderFn
      ${false} | ${findPipelinesDashboard}
      ${true}  | ${findPipelinesDashboardClickhouse}
    `('when flag is $status', ({ status, finderFn }) => {
      it('renders component', () => {
        createWrapper({
          provide: {
            glFeatures: {
              ciImprovedProjectPipelineAnalytics: status,
            },
          },
        });

        expect(finderFn().exists()).toBe(true);
      });
    });
  });
});
