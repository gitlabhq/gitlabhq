import axios from '../lib/utils/axios_utils';

export default class MergeConflictsService {
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
