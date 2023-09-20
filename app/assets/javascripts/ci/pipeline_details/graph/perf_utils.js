import {
  PIPELINES_DETAIL_LINKS_MARK_CALCULATE_START,
  PIPELINES_DETAIL_LINKS_MARK_CALCULATE_END,
  PIPELINES_DETAIL_LINKS_MEASURE_CALCULATION,
  PIPELINES_DETAIL_LINK_DURATION,
  PIPELINES_DETAIL_LINKS_TOTAL,
  PIPELINES_DETAIL_LINKS_JOB_RATIO,
} from '~/performance/constants';

import { performanceMarkAndMeasure } from '~/performance/utils';
import { reportPerformance } from './api_utils';

export const beginPerfMeasure = () => {
  performanceMarkAndMeasure({ mark: PIPELINES_DETAIL_LINKS_MARK_CALCULATE_START });
};

export const finishPerfMeasureAndSend = (numLinks, numGroups, metricsPath) => {
  performanceMarkAndMeasure({
    mark: PIPELINES_DETAIL_LINKS_MARK_CALCULATE_END,
    measures: [
      {
        name: PIPELINES_DETAIL_LINKS_MEASURE_CALCULATION,
        start: PIPELINES_DETAIL_LINKS_MARK_CALCULATE_START,
      },
    ],
  });

  window.requestAnimationFrame(() => {
    const duration = window.performance.getEntriesByName(
      PIPELINES_DETAIL_LINKS_MEASURE_CALCULATION,
    )[0]?.duration;

    if (!duration) {
      return;
    }

    const data = {
      histograms: [
        { name: PIPELINES_DETAIL_LINK_DURATION, value: duration / 1000 },
        { name: PIPELINES_DETAIL_LINKS_TOTAL, value: numLinks },
        {
          name: PIPELINES_DETAIL_LINKS_JOB_RATIO,
          value: numLinks / numGroups,
        },
      ],
    };

    reportPerformance(metricsPath, data);
  });
};
