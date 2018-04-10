/* eslint-disable func-names, space-before-function-paren, wrap-iife, quotes, no-var, object-shorthand, consistent-return, no-unused-vars, comma-dangle, vars-on-top, prefer-template, max-len */

import $ from 'jquery';
import { localTimeAgo } from './lib/utils/datetime_utility';
import axios from './lib/utils/axios_utils';

export default class Compare {
  constructor(opts) {
    this.opts = opts;
    this.source_loading = $(".js-source-loading");
    this.target_loading = $(".js-target-loading");
    $('.js-compare-dropdown').each((function(_this) {
      return function(i, dropdown) {
        var $dropdown;
        $dropdown = $(dropdown);
        return $dropdown.glDropdown({
          selectable: true,
          fieldName: $dropdown.data('fieldName'),
          filterable: true,
          id: function(obj, $el) {
            return $el.data('id');
          },
          toggleLabel: function(obj, $el) {
            return $el.text().trim();
          },
          clicked: function(e, el) {
            if ($dropdown.is('.js-target-branch')) {
              return _this.getTargetHtml();
            } else if ($dropdown.is('.js-source-branch')) {
              return _this.getSourceHtml();
            } else if ($dropdown.is('.js-target-project')) {
              return _this.getTargetProject();
            }
          }
        });
      };
    })(this));
    this.initialState();
  }

  initialState() {
    this.getSourceHtml();
    this.getTargetHtml();
  }

  getTargetProject() {
    $('.mr_target_commit').empty();

    return axios.get(this.opts.targetProjectUrl, {
      params: {
        target_project_id: $("input[name='merge_request[target_project_id]']").val(),
      },
    }).then(({ data }) => {
      $('.js-target-branch-dropdown .dropdown-content').html(data);
    });
  }

  getSourceHtml() {
    return this.constructor.sendAjax(this.opts.sourceBranchUrl, this.source_loading, '.mr_source_commit', {
      ref: $("input[name='merge_request[source_branch]']").val()
    });
  }

  getTargetHtml() {
    return this.constructor.sendAjax(this.opts.targetBranchUrl, this.target_loading, '.mr_target_commit', {
      target_project_id: $("input[name='merge_request[target_project_id]']").val(),
      ref: $("input[name='merge_request[target_branch]']").val()
    });
  }

  static sendAjax(url, loading, target, params) {
    const $target = $(target);

    loading.show();
    $target.empty();

    return axios.get(url, {
      params,
    }).then(({ data }) => {
      loading.hide();
      $target.html(data);
      const className = '.' + $target[0].className.replace(' ', '.');
      localTimeAgo($('.js-timeago', className));
    });
  }
}
