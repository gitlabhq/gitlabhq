/* global gl, Flash */
/* eslint-disable no-param-reassign */

((gl) => {
  const pageValues = (headers) => {
    const normalized = gl.utils.normalizeHeaders(headers);
    const paginationInfo = gl.utils.parseIntPagination(normalized);
    return paginationInfo;
  };

  gl.PipelineStore = class {
    fetchDataLoop(Vue, pageNum, url, apiScope) {
      this.pageRequest = true;

      return this.$http.get(`${url}?scope=${apiScope}&page=${pageNum}`)
      .then((response) => {
        const pageInfo = pageValues(response.headers);
        this.pageInfo = Object.assign({}, this.pageInfo, pageInfo);

        const res = JSON.parse(response.body);
        this.count = Object.assign({}, this.count, res.count);
        this.pipelines = Object.assign([], this.pipelines, res.pipelines);

        this.pageRequest = false;
      }, () => {
        this.pageRequest = false;
        return new Flash('An error occurred while fetching the pipelines, please reload the page again.');
      });
    }
  };
})(window.gl || (window.gl = {}));
