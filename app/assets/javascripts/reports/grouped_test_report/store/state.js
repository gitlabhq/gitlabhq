import { s__ } from '~/locale';
import { fieldTypes } from '../../constants';

export default () => ({
  endpoint: null,

  isLoading: false,
  hasError: false,

  status: null,

  summary: {
    total: 0,
    resolved: 0,
    failed: 0,
    errored: 0,
  },

  /**
   * Each report will have the following format:
   * {
   *   name: {String},
   *   summary: {
   *     total: {Number},
   *     resolved: {Number},
   *     failed: {Number},
   *     errored: {Number},
   *   },
   *   new_failures: {Array.<Object>},
   *   resolved_failures: {Array.<Object>},
   *   existing_failures: {Array.<Object>},
   *   new_errors: {Array.<Object>},
   *   resolved_errors: {Array.<Object>},
   *   existing_errors: {Array.<Object>},
   * }
   */
  reports: [],

  modal: {
    title: null,
    open: false,

    data: {
      classname: {
        value: null,
        text: s__('Reports|Classname'),
        type: fieldTypes.text,
      },
      filename: {
        value: null,
        text: s__('Reports|Filename'),
        type: fieldTypes.link,
      },
      execution_time: {
        value: null,
        text: s__('Reports|Execution time'),
        type: fieldTypes.seconds,
      },
      failure: {
        value: null,
        text: s__('Reports|Failure'),
        type: fieldTypes.codeBlock,
      },
      system_output: {
        value: null,
        text: s__('Reports|System output'),
        type: fieldTypes.codeBlock,
      },
    },
  },
});
