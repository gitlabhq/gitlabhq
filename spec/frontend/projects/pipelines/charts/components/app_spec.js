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
        glFeatures: {
          ciImprovedProjectPipelineAnalytics: true,
        },
        ...provide,
      },
      ...options,
    });
  };

  const findGlTabs = () => wrapper.findComponent(GlTabs);

  const findPipelinesDashboard = () => wrapper.findComponent(PipelinesDashboard);
  const findPipelinesDashboardClickhouse = () =>
    wrapper.findComponent(PipelinesDashboardClickhouse);

  describe('when clickhouse for analytics is disabled', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('does not render tabs', () => {
      // tabs are only shown in EE
      expect(findGlTabs().exists()).toBe(false);
    });

    it('shows pipelines dashboard', () => {
      expect(findPipelinesDashboard().exists()).toBe(true);
      expect(findPipelinesDashboardClickhouse().exists()).toBe(false);
    });
  });

  describe('when clickhouse for analytics is enabled', () => {
    beforeEach(() => {
      createWrapper({
        provide: {
          clickHouseEnabledForAnalytics: true,
        },
      });
    });

    it('does not render tabs', () => {
      // tabs are only shown in EE
      expect(findGlTabs().exists()).toBe(false);
    });

    it('shows pipelines dashboard with clickhouse', () => {
      expect(findPipelinesDashboardClickhouse().exists()).toBe(true);
      expect(findPipelinesDashboard().exists()).toBe(false);
    });
  });

  describe('ci_improved_project_pipeline_analytics feature flag', () => {
    describe('when flag is disabled', () => {
      it('renders component', () => {
        createWrapper({
          provide: {
            glFeatures: {
              ciImprovedProjectPipelineAnalytics: false,
            },
          },
        });

        expect(findPipelinesDashboard().exists()).toBe(true);
      });
    });
  });
});
