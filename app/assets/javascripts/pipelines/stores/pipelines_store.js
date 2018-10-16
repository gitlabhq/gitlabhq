import { parseIntPagination, normalizeHeaders } from '../../lib/utils/common_utils';
import { addRemainingTime } from '../helpers';

export default class PipelinesStore {
  constructor() {
    this.state = {};

    this.state.pipelines = [];
    this.state.count = {};
    this.state.pageInfo = {};
  }

  storePipelines(pipelines = []) {
    this.state.pipelines = pipelines;
    this.updateDelayedJobs();
  }

  storeCount(count = {}) {
    this.state.count = count;
  }

  storePagination(pagination = {}) {
    let paginationInfo;

    if (Object.keys(pagination).length) {
      const normalizedHeaders = normalizeHeaders(pagination);
      paginationInfo = parseIntPagination(normalizedHeaders);
    } else {
      paginationInfo = pagination;
    }

    this.state.pageInfo = paginationInfo;
  }

  updateDelayedJobs() {
    this.state.pipelines = this.state.pipelines.map(pipeline => {
      const { details } = pipeline;
      if (!details || !details.scheduled_actions || details.scheduled_actions.length === 0) {
        return pipeline;
      }

      return {
        ...pipeline,
        details: {
          ...details,
          scheduled_actions: details.scheduled_actions.map(addRemainingTime),
        },
      };
    });

    window.setTimeout(() => this.updateDelayedJobs(), 1000);
  }
}
