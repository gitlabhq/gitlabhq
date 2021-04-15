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
            shouldRenderDeploymentFrequencyCharts: true,
            shouldRenderLeadTimeCharts: true,
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
  const findLeadTimeCharts = () => wrapper.find(LeadTimeChartsStub);
  const findDeploymentFrequencyCharts = () => wrapper.find(DeploymentFrequencyChartsStub);
  const findPipelineCharts = () => wrapper.find(PipelineCharts);

  const expectCorrectTabs = ({ pipelines, leadTime, deploymentFreqency }) => {
    it('renders the expected tabs', () => {
      expect(findGlTabs().exists()).toBe(true);

      const allTabTitles = findAllGlTabs().wrappers.map((w) => w.attributes('title'));

      if (pipelines) {
        expect(allTabTitles).toContain('Pipelines');
        expect(findPipelineCharts().exists()).toBe(true);
      }

      if (deploymentFreqency) {
        expect(allTabTitles).toContain('Deployments');
        expect(findDeploymentFrequencyCharts().exists()).toBe(true);
      }

      if (leadTime) {
        expect(allTabTitles).toContain('Lead Time');
        expect(findLeadTimeCharts().exists()).toBe(true);
      }
    });
  };

  describe('when all charts are available', () => {
    beforeEach(() => {
      createComponent();
    });

    expectCorrectTabs({ pipelines: true, deploymentFreqency: true, leadTime: true });

    it('sets the tab and url when a tab is clicked', async () => {
      let chartsPath;
      setWindowLocation(`${TEST_HOST}/gitlab-org/gitlab-test/-/pipelines/charts`);

      mergeUrlParams.mockImplementation(({ chart }, path) => {
        expect(chart).toBe('deployments');
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
      chart            | tab
      ${'lead-time'}   | ${'2'}
      ${'deployments'} | ${'1'}
      ${'pipelines'}   | ${'0'}
      ${'fake'}        | ${'0'}
      ${''}            | ${'0'}
    `('shows the correct tab for URL parameter "$chart"', ({ chart, tab }) => {
      setWindowLocation(`${TEST_HOST}/gitlab-org/gitlab-test/-/pipelines/charts?chart=${chart}`);
      getParameterValues.mockImplementation((name) => {
        expect(name).toBe('chart');
        return chart ? [chart] : [];
      });
      createComponent({ provide: { shouldRenderDeploymentFrequencyCharts: true } });
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

      createComponent({ provide: { shouldRenderDeploymentFrequencyCharts: true } });

      expect(findGlTabs().attributes('value')).toBe('0');

      getParameterValues.mockImplementationOnce((name) => {
        expect(name).toBe('chart');
        return ['deployments'];
      });

      popstateHandler();

      await wrapper.vm.$nextTick();

      expect(findGlTabs().attributes('value')).toBe('1');
    });
  });

  describe('when shouldRenderDeploymentFrequencyCharts is false', () => {
    beforeEach(() => {
      createComponent({ provide: { shouldRenderDeploymentFrequencyCharts: false } });
    });

    expectCorrectTabs({ pipelines: true, deploymentFreqency: false, leadTime: true });
  });

  describe('when shouldRenderLeadTimeCharts is false', () => {
    beforeEach(() => {
      createComponent({ provide: { shouldRenderLeadTimeCharts: false } });
    });

    expectCorrectTabs({ pipelines: true, deploymentFreqency: true, leadTime: false });
  });

  describe('when shouldRenderDeploymentFrequencyCharts and shouldRenderLeadTimeCharts are false', () => {
    beforeEach(() => {
      createComponent({
        provide: {
          shouldRenderDeploymentFrequencyCharts: false,
          shouldRenderLeadTimeCharts: false,
        },
      });
    });

    it('does not render tabs', () => {
      expect(findGlTabs().exists()).toBe(false);
    });

    it('renders the pipeline charts', () => {
      expect(findPipelineCharts().exists()).toBe(true);
    });
  });
});
