import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';

export default class PipelinesStore {
  constructor() {
    this.state = {};

    this.state.pipelines = [];
    this.state.count = {};
    this.state.pageInfo = {};

    // Used in MR Pipelines tab
    this.state.isRunningMergeRequestPipeline = false;
  }

  storePipelines(pipelines = [], isUsingAsyncPipelineCreation) {
    if (isUsingAsyncPipelineCreation && pipelines.length) {
      const firstPipelineFromTable = this.state.pipelines[0];
      const firstPipelineFromRequest = pipelines[0];

      if (firstPipelineFromTable?.created_at !== firstPipelineFromRequest?.created_at) {
        this.toggleIsRunningPipeline(false);
      }
    }

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

  /**
   * Toggles the isRunningPipeline flag
   *
   * @param {Boolean} value
   */
  toggleIsRunningPipeline(value = false) {
    this.state.isRunningMergeRequestPipeline = value;
  }
}
