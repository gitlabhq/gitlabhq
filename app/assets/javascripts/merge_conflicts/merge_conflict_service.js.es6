/* eslint-disable */
((global) => {
  global.mergeConflicts = global.mergeConflicts || {};

  class mergeConflictsService {
    constructor(options) {
      this.conflictsPath = options.conflictsPath;
      this.resolveConflictsPath = options.resolveConflictsPath;
    }

    fetchConflictsData() {
      return $.ajax({
        dataType: 'json',
        url: this.conflictsPath
      });
    }

    submitResolveConflicts(data) {
      return $.ajax({
        url: this.resolveConflictsPath,
        data: JSON.stringify(data),
        contentType: 'application/json',
        dataType: 'json',
        method: 'POST'
      });
    }
  };

  global.mergeConflicts.mergeConflictsService = mergeConflictsService;

})(window.gl || (window.gl = {}));
