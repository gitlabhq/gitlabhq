import { parseIntPagination, normalizeHeaders } from '../../lib/utils/common_utils';

export default class PipelinesStore {
  constructor() {
    this.state = {};

    this.state.pipelines = [];
    this.state.count = {
      all: 0,
      finished: 0,
      pending: 0,
      running: 0,
    };
    this.state.pageInfo = {};
  }

  storePipelines(pipelines = []) {
    this.state.pipelines = pipelines;
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
}
