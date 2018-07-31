import { s__ } from '~/locale';
import { fieldTypes } from '../constants';

export default () => ({
  endpoint: null,

  isLoading: false,
  hasError: false,

  status: null,

  summary: {
    total: 0,
    resolved: 0,
    failed: 0,
  },

  /**
   * Each report will have the following format:
   * {
   *   name: {String},
   *   summary: {
   *     total: {Number},
   *     resolved: {Number},
   *     failed: {Number},
   *   },
   *   new_failures: {Array.<Object>},
   *   resolved_failures: {Array.<Object>},
   *   existing_failures: {Array.<Object>},
   * }
   */
  reports: [],

  modal: {
    title: null,

    status: null,

    data: {
      class: {
        value: null,
        text: s__('Reports|Class'),
        type: fieldTypes.link,
      },
      execution_time: {
        value: null,
        text: s__('Reports|Execution time'),
        type: fieldTypes.miliseconds,
      },
      failure: {
        value: null,
        text: s__('Reports|Failure'),
        type: fieldTypes.codeBock,
      },
      system_output: {
        value: null,
        text: s__('Reports|System output'),
        type: fieldTypes.codeBock,
      },
    },
  },

});
