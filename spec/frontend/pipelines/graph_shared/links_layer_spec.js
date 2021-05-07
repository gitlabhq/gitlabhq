import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import {
  PIPELINES_DETAIL_LINK_DURATION,
  PIPELINES_DETAIL_LINKS_TOTAL,
  PIPELINES_DETAIL_LINKS_JOB_RATIO,
} from '~/performance/constants';
import * as perfUtils from '~/performance/utils';
import * as Api from '~/pipelines/components/graph_shared/api';
import LinksInner from '~/pipelines/components/graph_shared/links_inner.vue';
import LinksLayer from '~/pipelines/components/graph_shared/links_layer.vue';
import * as sentryUtils from '~/pipelines/utils';
import { generateResponse, mockPipelineResponse } from '../graph/mock_data';

describe('links layer component', () => {
  let wrapper;

  const findLinksInner = () => wrapper.find(LinksInner);

  const pipeline = generateResponse(mockPipelineResponse, 'root/fungi-xoxo');
  const containerId = `pipeline-links-container-${pipeline.id}`;
  const slotContent = "<div>Ceci n'est pas un graphique</div>";

  const defaultProps = {
    containerId,
    containerMeasurements: { width: 400, height: 400 },
    pipelineId: pipeline.id,
    pipelineData: pipeline.stages,
    showLinks: false,
  };

  const createComponent = ({ mountFn = shallowMount, props = {} } = {}) => {
    wrapper = mountFn(LinksLayer, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      slots: {
        default: slotContent,
      },
      stubs: {
        'links-inner': true,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with show links off', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the default slot', () => {
      expect(wrapper.html()).toContain(slotContent);
    });

    it('does not render inner links component', () => {
      expect(findLinksInner().exists()).toBe(false);
    });
  });

  describe('with show links on', () => {
    beforeEach(() => {
      createComponent({
        props: {
          showLinks: true,
        },
      });
    });

    it('renders the default slot', () => {
      expect(wrapper.html()).toContain(slotContent);
    });

    it('renders the inner links component', () => {
      expect(findLinksInner().exists()).toBe(true);
    });
  });

  describe('with width or height measurement at 0', () => {
    beforeEach(() => {
      createComponent({ props: { containerMeasurements: { width: 0, height: 100 } } });
    });

    it('renders the default slot', () => {
      expect(wrapper.html()).toContain(slotContent);
    });

    it('does not render the inner links component', () => {
      expect(findLinksInner().exists()).toBe(false);
    });
  });

  describe('performance metrics', () => {
    const metricsPath = '/root/project/-/ci/prometheus_metrics/histograms.json';
    let markAndMeasure;
    let reportToSentry;
    let reportPerformance;
    let mock;

    beforeEach(() => {
      jest.spyOn(window, 'requestAnimationFrame').mockImplementation((cb) => cb());
      markAndMeasure = jest.spyOn(perfUtils, 'performanceMarkAndMeasure');
      reportToSentry = jest.spyOn(sentryUtils, 'reportToSentry');
      reportPerformance = jest.spyOn(Api, 'reportPerformance');
    });

    describe('with no metrics config object', () => {
      beforeEach(() => {
        createComponent();
      });

      it('is not called', () => {
        expect(markAndMeasure).not.toHaveBeenCalled();
        expect(reportToSentry).not.toHaveBeenCalled();
        expect(reportPerformance).not.toHaveBeenCalled();
      });
    });

    describe('with metrics config set to false', () => {
      beforeEach(() => {
        createComponent({
          props: {
            metricsConfig: {
              collectMetrics: false,
              metricsPath: '/path/to/metrics',
            },
          },
        });
      });

      it('is not called', () => {
        expect(markAndMeasure).not.toHaveBeenCalled();
        expect(reportToSentry).not.toHaveBeenCalled();
        expect(reportPerformance).not.toHaveBeenCalled();
      });
    });

    describe('with no metrics path', () => {
      beforeEach(() => {
        createComponent({
          props: {
            metricsConfig: {
              collectMetrics: true,
              metricsPath: '',
            },
          },
        });
      });

      it('is not called', () => {
        expect(markAndMeasure).not.toHaveBeenCalled();
        expect(reportToSentry).not.toHaveBeenCalled();
        expect(reportPerformance).not.toHaveBeenCalled();
      });
    });

    describe('with metrics path and collect set to true', () => {
      const duration = 875;
      const numLinks = 7;
      const totalGroups = 8;
      const metricsData = {
        histograms: [
          { name: PIPELINES_DETAIL_LINK_DURATION, value: duration / 1000 },
          { name: PIPELINES_DETAIL_LINKS_TOTAL, value: numLinks },
          {
            name: PIPELINES_DETAIL_LINKS_JOB_RATIO,
            value: numLinks / totalGroups,
          },
        ],
      };

      describe('when no duration is obtained', () => {
        beforeEach(() => {
          jest.spyOn(window.performance, 'getEntriesByName').mockImplementation(() => {
            return [];
          });

          createComponent({
            props: {
              metricsConfig: {
                collectMetrics: true,
                path: metricsPath,
              },
            },
          });
        });

        it('attempts to collect metrics', () => {
          expect(markAndMeasure).toHaveBeenCalled();
          expect(reportPerformance).not.toHaveBeenCalled();
          expect(reportToSentry).not.toHaveBeenCalled();
        });
      });

      describe('with duration and no error', () => {
        beforeEach(() => {
          mock = new MockAdapter(axios);
          mock.onPost(metricsPath).reply(200, {});

          jest.spyOn(window.performance, 'getEntriesByName').mockImplementation(() => {
            return [{ duration }];
          });

          createComponent({
            props: {
              metricsConfig: {
                collectMetrics: true,
                path: metricsPath,
              },
            },
          });
        });

        afterEach(() => {
          mock.restore();
        });

        it('it calls reportPerformance with expected arguments', () => {
          expect(markAndMeasure).toHaveBeenCalled();
          expect(reportPerformance).toHaveBeenCalled();
          expect(reportPerformance).toHaveBeenCalledWith(metricsPath, metricsData);
          expect(reportToSentry).not.toHaveBeenCalled();
        });
      });
    });
  });
});
