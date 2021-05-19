import { GlTabs, GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { merge } from 'lodash';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { mergeUrlParams, updateHistory, getParameterValues } from '~/lib/utils/url_utility';
import Component from '~/projects/pipelines/charts/components/app.vue';
import PipelineCharts from '~/projects/pipelines/charts/components/pipeline_charts.vue';

jest.mock('~/lib/utils/url_utility');

const DeploymentFrequencyChartsStub = { name: 'DeploymentFrequencyCharts', render: () => {} };
const LeadTimeChartsStub = { name: 'LeadTimeCharts', render: () => {} };

describe('ProjectsPipelinesChartsApp', () => {
  let wrapper;

  function createComponent(mountOptions = {}) {
    wrapper = shallowMount(
      Component,
      merge(
        {},
        {
          provide: {
            shouldRenderDoraCharts: true,
          },
          stubs: {
            DeploymentFrequencyCharts: DeploymentFrequencyChartsStub,
            LeadTimeCharts: LeadTimeChartsStub,
          },
        },
        mountOptions,
      ),
    );
  }

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlTabs = () => wrapper.find(GlTabs);
  const findAllGlTabs = () => wrapper.findAll(GlTab);
  const findGlTabAtIndex = (index) => findAllGlTabs().at(index);
  const findLeadTimeCharts = () => wrapper.find(LeadTimeChartsStub);
  const findDeploymentFrequencyCharts = () => wrapper.find(DeploymentFrequencyChartsStub);
  const findPipelineCharts = () => wrapper.find(PipelineCharts);

  describe('when all charts are available', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders tabs', () => {
      expect(findGlTabs().exists()).toBe(true);

      expect(findGlTabAtIndex(0).attributes('title')).toBe('Pipelines');
      expect(findGlTabAtIndex(1).attributes('title')).toBe('Deployment frequency');
      expect(findGlTabAtIndex(2).attributes('title')).toBe('Lead time');
    });

    it('renders the pipeline charts', () => {
      expect(findPipelineCharts().exists()).toBe(true);
    });

    it('renders the deployment frequency charts', () => {
      expect(findDeploymentFrequencyCharts().exists()).toBe(true);
    });

    it('renders the lead time charts', () => {
      expect(findLeadTimeCharts().exists()).toBe(true);
    });

    it('sets the tab and url when a tab is clicked', async () => {
      let chartsPath;
      setWindowLocation(`${TEST_HOST}/gitlab-org/gitlab-test/-/pipelines/charts`);

      mergeUrlParams.mockImplementation(({ chart }, path) => {
        expect(chart).toBe('deployment-frequency');
        expect(path).toBe(window.location.pathname);
        chartsPath = `${path}?chart=${chart}`;
        return chartsPath;
      });

      updateHistory.mockImplementation(({ url }) => {
        expect(url).toBe(chartsPath);
      });
      const tabs = findGlTabs();

      expect(tabs.attributes('value')).toBe('0');

      tabs.vm.$emit('input', 1);

      await wrapper.vm.$nextTick();

      expect(tabs.attributes('value')).toBe('1');
    });

    it('should not try to push history if the tab does not change', async () => {
      setWindowLocation(`${TEST_HOST}/gitlab-org/gitlab-test/-/pipelines/charts`);

      mergeUrlParams.mockImplementation(({ chart }, path) => `${path}?chart=${chart}`);

      const tabs = findGlTabs();

      expect(tabs.attributes('value')).toBe('0');

      tabs.vm.$emit('input', 0);

      await wrapper.vm.$nextTick();

      expect(updateHistory).not.toHaveBeenCalled();
    });
  });

  describe('when provided with a query param', () => {
    it.each`
      chart                     | tab
      ${'lead-time'}            | ${'2'}
      ${'deployment-frequency'} | ${'1'}
      ${'pipelines'}            | ${'0'}
      ${'fake'}                 | ${'0'}
      ${''}                     | ${'0'}
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

      await wrapper.vm.$nextTick();

      expect(findGlTabs().attributes('value')).toBe('1');
    });
  });

  describe('when the dora charts are not available', () => {
    beforeEach(() => {
      createComponent({ provide: { shouldRenderDoraCharts: false } });
    });

    it('does not render tabs', () => {
      expect(findGlTabs().exists()).toBe(false);
    });

    it('renders the pipeline charts', () => {
      expect(findPipelineCharts().exists()).toBe(true);
    });
  });
});
