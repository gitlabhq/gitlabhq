/* eslint-disable consistent-return */

import fuzzaldrinPlus from 'fuzzaldrin-plus';
import $ from 'jquery';
import { debounce } from 'lodash';
import { isObject } from '~/lib/utils/type_utility';

const BLUR_KEYCODES = [27, 40];

const HAS_VALUE_CLASS = 'has-value';

export class GitLabDropdownFilter {
  constructor(input, options) {
    let ref;
    this.input = input;
    this.options = options;
    // eslint-disable-next-line no-cond-assign
    this.filterInputBlur = (ref = this.options.filterInputBlur) != null ? ref : true;
    const $inputContainer = this.input.parent();
    const $clearButton = $inputContainer.find('.js-dropdown-input-clear');
    const filterRemoteDebounced = debounce(() => {
      $inputContainer.parent().addClass('is-loading');

      return this.options.query(this.input.val(), (data) => {
        $inputContainer.parent().removeClass('is-loading');
        return this.options.callback(data);
      });
    }, 500);

    $clearButton.on('click', (e) => {
      // Clear click
      e.preventDefault();
      e.stopPropagation();
      return this.input.val('').trigger('input').focus();
    });
    // Key events
    this.input
      .on('keydown', (e) => {
        const keyCode = e.which;
        if (keyCode === 13 && !options.elIsInput) {
          e.preventDefault();
        }
      })
      .on('input', () => {
        if (this.input.val() !== '' && !$inputContainer.hasClass(HAS_VALUE_CLASS)) {
          $inputContainer.addClass(HAS_VALUE_CLASS);
        } else if (this.input.val() === '' && $inputContainer.hasClass(HAS_VALUE_CLASS)) {
          $inputContainer.removeClass(HAS_VALUE_CLASS);
        }
        // Only filter asynchronously only if option remote is set
        if (this.options.remote) {
          return filterRemoteDebounced();
        }
        return this.filter(this.input.val());
      });
  }

  static shouldBlur(keyCode) {
    return BLUR_KEYCODES.indexOf(keyCode) !== -1;
  }

  filter(searchText) {
    let group;
    let results;
    let tmp;
    if (this.options.onFilter) {
      this.options.onFilter(searchText);
    }
    const data = this.options.data();
    if (data != null && !this.options.filterByText) {
      results = data;
      if (searchText !== '') {
        // When data is an array of objects therefore [object Array] e.g.
        // [
        //   { prop: 'foo' },
        //   { prop: 'baz' }
        // ]
        if (Array.isArray(data)) {
          results = fuzzaldrinPlus.filter(data, searchText, {
            key: this.options.keys,
          });
        }
        // If data is grouped therefore an [object Object]. e.g.
        // {
        //   groupName1: [
        //     { prop: 'foo' },
        //     { prop: 'baz' }
        //   ],
        //   groupName2: [
        //     { prop: 'abc' },
        //     { prop: 'def' }
        //   ]
        // }
        else if (isObject(data)) {
          results = {};
          Object.keys(data).forEach((key) => {
            group = data[key];
            tmp = fuzzaldrinPlus.filter(group, searchText, {
              key: this.options.keys,
            });
            if (tmp.length) {
              results[key] = tmp.map((item) => item);
            }
          });
        }
      }
      return this.options.callback(results);
    }
    const elements = this.options.elements();
    if (searchText) {
      // eslint-disable-next-line func-names
      elements.each(function () {
        const $el = $(this);
        const matches = fuzzaldrinPlus.match($el.text().trim(), searchText);
        if (!$el.is('.dropdown-header')) {
          if (matches.length) {
            return $el.show().removeClass('option-hidden');
          }
          return $el.hide().addClass('option-hidden');
        }
      });
    } else {
      elements.show().removeClass('option-hidden');
    }

    elements
      .parent()
      .find('.dropdown-menu-empty-item')
      .toggleClass('hidden', elements.is(':visible'));
  }
}
