/* eslint-disable no-param-reassign, comma-dangle */
import axios from '../lib/utils/axios_utils';

((global) => {
  global.mergeConflicts = global.mergeConflicts || {};

  class mergeConflictsService {
    constructor(options) {
      this.conflictsPath = options.conflictsPath;
      this.resolveConflictsPath = options.resolveConflictsPath;
    }

    fetchConflictsData() {
      return axios.get(this.conflictsPath);
    }

    submitResolveConflicts(data) {
      return axios.post(this.resolveConflictsPath, data);
    }
  }

  global.mergeConflicts.mergeConflictsService = mergeConflictsService;
})(window.gl || (window.gl = {}));
