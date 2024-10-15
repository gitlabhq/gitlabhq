import { GlTabs, GlTab } from '@gitlab/ui';
import { merge } from 'lodash';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { mergeUrlParams, updateHistory, getParameterValues } from '~/lib/utils/url_utility';
import Component from '~/projects/pipelines/charts/components/app.vue';
import PipelineCharts from '~/projects/pipelines/charts/components/pipeline_charts.vue';
import PipelineChartsNew from '~/projects/pipelines/charts/components/pipeline_charts_new.vue';
import API from '~/api';
import { mockTracking } from 'helpers/tracking_helper';
import { SNOWPLOW_DATA_SOURCE, SNOWPLOW_SCHEMA } from '~/projects/pipelines/charts/constants';

jest.mock('~/lib/utils/url_utility');

const DeploymentFrequencyChartsStub = { name: 'DeploymentFrequencyCharts', render: () => {} };
const LeadTimeChartsStub = { name: 'LeadTimeCharts', render: () => {} };
const TimeToRestoreServiceChartsStub = { name: 'TimeToRestoreServiceCharts', render: () => {} };
const ChangeFailureRateChartsStub = { name: 'ChangeFailureRateCharts', render: () => {} };
const ProjectQualitySummaryStub = { name: 'ProjectQualitySummary', render: () => {} };

describe('ProjectsPipelinesChartsApp', () => {
  let wrapper;

  function createComponent(mountOptions = {}) {
    wrapper = shallowMountExtended(
      Component,
      merge(
        {},
        {
          provide: {
            shouldRenderDoraCharts: true,
            shouldRenderQualitySummary: true,
          },
          stubs: {
            DeploymentFrequencyCharts: DeploymentFrequencyChartsStub,
            LeadTimeCharts: LeadTimeChartsStub,
            TimeToRestoreServiceCharts: TimeToRestoreServiceChartsStub,
            ChangeFailureRateCharts: ChangeFailureRateChartsStub,
            ProjectQualitySummary: ProjectQualitySummaryStub,
          },
        },
        mountOptions,
      ),
    );
  }

  const findGlTabs = () => wrapper.findComponent(GlTabs);
  const findAllGlTabs = () => wrapper.findAllComponents(GlTab);
  const findGlTabAtIndex = (index) => findAllGlTabs().at(index);
  const findLeadTimeCharts = () => wrapper.findComponent(LeadTimeChartsStub);
  const findTimeToRestoreServiceCharts = () =>
    wrapper.findComponent(TimeToRestoreServiceChartsStub);
  const findChangeFailureRateCharts = () => wrapper.findComponent(ChangeFailureRateChartsStub);
  const findDeploymentFrequencyCharts = () => wrapper.findComponent(DeploymentFrequencyChartsStub);
  const findPipelineCharts = () => wrapper.findComponent(PipelineCharts);
  const findPipelineChartsNew = () => wrapper.findComponent(PipelineChartsNew);
  const findProjectQualitySummary = () => wrapper.findComponent(ProjectQualitySummaryStub);

  describe('when all charts are available', () => {
    beforeEach(() => {
      createComponent();
    });

    describe.each`
      title                        | finderFn                          | index
      ${'Pipelines'}               | ${findPipelineCharts}             | ${0}
      ${'Deployment frequency'}    | ${findDeploymentFrequencyCharts}  | ${1}
      ${'Lead time'}               | ${findLeadTimeCharts}             | ${2}
      ${'Time to restore service'} | ${findTimeToRestoreServiceCharts} | ${3}
      ${'Change failure rate'}     | ${findChangeFailureRateCharts}    | ${4}
      ${'Project quality'}         | ${findProjectQualitySummary}      | ${5}
    `('Tabs', ({ title, finderFn, index }) => {
      it(`renders tab with a title ${title} at index ${index}`, () => {
        expect(findGlTabAtIndex(index).attributes('title')).toBe(title);
      });

      it(`renders the ${title} chart`, () => {
        expect(finderFn().exists()).toBe(true);
      });

      it(`updates the current tab and url when the ${title} tab is clicked`, async () => {
        let chartsPath;
        const tabName = title.toLowerCase().replace(/\s/g, '-');

        setWindowLocation(`${TEST_HOST}/gitlab-org/gitlab-test/-/pipelines/charts`);

        mergeUrlParams.mockImplementation(({ chart }, path) => {
          expect(chart).toBe(tabName);
          expect(path).toBe(window.location.pathname);
          chartsPath = `${path}?chart=${chart}`;
          return chartsPath;
        });

        updateHistory.mockImplementation(({ url }) => {
          expect(url).toBe(chartsPath);
        });
        const tabs = findGlTabs();

        expect(tabs.attributes('value')).toBe('0');

        tabs.vm.$emit('input', index);

        await nextTick();

        expect(tabs.attributes('value')).toBe(index.toString());
      });
    });

    it('should not try to push history if the tab does not change', async () => {
      setWindowLocation(`${TEST_HOST}/gitlab-org/gitlab-test/-/pipelines/charts`);

      mergeUrlParams.mockImplementation(({ chart }, path) => `${path}?chart=${chart}`);

      const tabs = findGlTabs();

      expect(tabs.attributes('value')).toBe('0');

      tabs.vm.$emit('input', 0);

      await nextTick();

      expect(updateHistory).not.toHaveBeenCalled();
    });

    describe('event tracking', () => {
      describe('Internal Events RedisHLL events', () => {
        it.each`
          testId                           | event
          ${'pipelines-tab'}               | ${'p_analytics_ci_cd_pipelines'}
          ${'deployment-frequency-tab'}    | ${'p_analytics_ci_cd_deployment_frequency'}
          ${'lead-time-tab'}               | ${'p_analytics_ci_cd_lead_time'}
          ${'time-to-restore-service-tab'} | ${'visit_ci_cd_time_to_restore_service_tab'}
          ${'change-failure-rate-tab'}     | ${'visit_ci_cd_failure_rate_tab'}
        `('tracks the $event event when clicked', ({ testId, event }) => {
          const trackApiSpy = jest.spyOn(API, 'trackInternalEvent');

          expect(trackApiSpy).not.toHaveBeenCalled();

          wrapper.findByTestId(testId).vm.$emit('click');

          expect(trackApiSpy).toHaveBeenCalledWith(event, {});
        });
      });

      describe('Snowplow events', () => {
        it.each`
          testId                        | event
          ${'pipelines-tab'}            | ${'p_analytics_ci_cd_pipelines'}
          ${'deployment-frequency-tab'} | ${'p_analytics_ci_cd_deployment_frequency'}
          ${'lead-time-tab'}            | ${'p_analytics_ci_cd_lead_time'}
        `('tracks the $event event when clicked', ({ testId, event }) => {
          const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

          wrapper.findByTestId(testId).vm.$emit('click');

          expect(trackingSpy).toHaveBeenCalledWith(undefined, event, {
            context: {
              schema: SNOWPLOW_SCHEMA,
              data: {
                event_name: event,
                data_source: SNOWPLOW_DATA_SOURCE,
              },
            },
          });
        });
      });
    });
  });

  describe('when provided with a query param', () => {
    it.each`
      chart                        | tab
      ${'change-failure-rate'}     | ${'4'}
      ${'time-to-restore-service'} | ${'3'}
      ${'lead-time'}               | ${'2'}
      ${'deployment-frequency'}    | ${'1'}
      ${'pipelines'}               | ${'0'}
      ${'fake'}                    | ${'0'}
      ${''}                        | ${'0'}
    `('shows the correct tab for URL parameter "$chart"', ({ chart, tab }) => {
      setWindowLocation(`${TEST_HOST}/gitlab-org/gitlab-test/-/pipelines/charts?chart=${chart}`);
      getParameterValues.mockImplementation((name) => {
        expect(name).toBe('chart');
        return chart ? [chart] : [];
      });
      createComponent();
      expect(findGlTabs().attributes('value')).toBe(tab);
    });

    it('should set the tab when the back button is clicked', async () => {
      let popstateHandler;

      window.addEventListener = jest.fn();

      window.addEventListener.mockImplementation((event, handler) => {
        if (event === 'popstate') {
          popstateHandler = handler;
        }
      });

      getParameterValues.mockImplementation((name) => {
        expect(name).toBe('chart');
        return [];
      });

      createComponent();

      expect(findGlTabs().attributes('value')).toBe('0');

      getParameterValues.mockImplementationOnce((name) => {
        expect(name).toBe('chart');
        return ['deployment-frequency'];
      });

      popstateHandler();

      await nextTick();

      expect(findGlTabs().attributes('value')).toBe('1');
    });
  });

  describe('when the dora charts are not available and project quality summary is not available', () => {
    beforeEach(() => {
      createComponent({
        provide: { shouldRenderDoraCharts: false, shouldRenderQualitySummary: false },
      });
    });

    it('does not render tabs', () => {
      expect(findGlTabs().exists()).toBe(false);
    });

    it('renders the pipeline charts', () => {
      expect(findPipelineCharts().exists()).toBe(true);
    });
  });

  describe('when the project quality summary is not available', () => {
    beforeEach(() => {
      createComponent({ provide: { shouldRenderQualitySummary: false } });
    });

    it('does not render the tab', () => {
      expect(findProjectQualitySummary().exists()).toBe(false);
    });
  });

  describe('ci_improved_project_pipeline_analytics feature flag', () => {
    describe.each`
      status   | finderFn
      ${false} | ${findPipelineCharts}
      ${true}  | ${findPipelineChartsNew}
    `('when flag is $status', ({ status, finderFn }) => {
      it('renders component', () => {
        createComponent({
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
