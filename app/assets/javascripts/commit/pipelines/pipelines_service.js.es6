/* globals Vue */
/* eslint-disable no-unused-vars, no-param-reassign */

/**
 * Pipelines service.
 *
 * Used to fetch the data used to render the pipelines table.
 * Used Vue.Resource
 */

window.gl = window.gl || {};
gl.pipelines = gl.pipelines || {};

class PipelinesService {
  constructor(root) {
    Vue.http.options.root = root;

    this.pipelines = Vue.resource(root);

    Vue.http.interceptors.push((request, next) => {
      // needed in order to not break the tests.
      if ($.rails) {
        request.headers['X-CSRF-Token'] = $.rails.csrfToken();
      }
      next();
    });
  }

  /**
   * Given the root param provided when the class is initialized, will
   * make a GET request.
   *
   * @return {Promise}
   */
  all() {
    return this.pipelines.get();
  }
}

gl.pipelines.PipelinesService = PipelinesService;

// const pageValues = (headers) => {
//   const normalized = gl.utils.normalizeHeaders(headers);
//
//   const paginationInfo = {
//     perPage: +normalized['X-PER-PAGE'],
//     page: +normalized['X-PAGE'],
//     total: +normalized['X-TOTAL'],
//     totalPages: +normalized['X-TOTAL-PAGES'],
//     nextPage: +normalized['X-NEXT-PAGE'],
//     previousPage: +normalized['X-PREV-PAGE'],
//   };
//
//   return paginationInfo;
// };

// gl.PipelineStore = class {
//   fetchDataLoop(Vue, pageNum, url, apiScope) {
//     const goFetch = () =>
//       this.$http.get(`${url}?scope=${apiScope}&page=${pageNum}`)
//         .then((response) => {
//           const pageInfo = pageValues(response.headers);
//           this.pageInfo = Object.assign({}, this.pageInfo, pageInfo);
//
//           const res = JSON.parse(response.body);
//           this.count = Object.assign({}, this.count, res.count);
//           this.pipelines = Object.assign([], this.pipelines, res);
//
//           this.pageRequest = false;
//         }, () => {
//           this.pageRequest = false;
//           return new Flash('Something went wrong on our end.');
//         });
//
//     goFetch();
//   }
// };
