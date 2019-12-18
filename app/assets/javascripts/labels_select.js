/* eslint-disable no-useless-return, func-names, no-underscore-dangle, no-new, consistent-return, no-shadow, no-param-reassign, no-lonely-if, no-else-return, dot-notation, no-empty */
/* global Issuable */
/* global ListLabel */

import $ from 'jquery';
import _ from 'underscore';
import { sprintf, s__, __ } from './locale';
import axios from './lib/utils/axios_utils';
import IssuableBulkUpdateActions from './issuable_bulk_update_actions';
import CreateLabelDropdown from './create_label';
import flash from './flash';
import ModalStore from './boards/stores/modal_store';
import boardsStore from './boards/stores/boards_store';
import { isScopedLabel } from '~/lib/utils/common_utils';

export default class LabelsSelect {
  constructor(els, options = {}) {
    const _this = this;

    let $els = $(els);

    if (!els) {
      $els = $('.js-label-select');
    }

    $els.each((i, dropdown) => {
      const $dropdown = $(dropdown);
      const $dropdownContainer = $dropdown.closest('.labels-filter');
      const namespacePath = $dropdown.data('namespacePath');
      const projectPath = $dropdown.data('projectPath');
      const issueUpdateURL = $dropdown.data('issueUpdate');
      let selectedLabel = $dropdown.data('selected');
      if (selectedLabel != null && !$dropdown.hasClass('js-multiselect')) {
        selectedLabel = selectedLabel.split(',');
      }
      const showNo = $dropdown.data('showNo');
      const showAny = $dropdown.data('showAny');
      const showMenuAbove = $dropdown.data('showMenuAbove');
      const defaultLabel = $dropdown.data('defaultLabel') || __('Label');
      const abilityName = $dropdown.data('abilityName');
      const $selectbox = $dropdown.closest('.selectbox');
      const $block = $selectbox.closest('.block');
      const $form = $dropdown.closest('form, .js-issuable-update');
      const $sidebarCollapsedValue = $block.find('.sidebar-collapsed-icon span');
      const $sidebarLabelTooltip = $block.find('.js-sidebar-labels-tooltip');
      const $value = $block.find('.value');
      const $dropdownMenu = $dropdown.parent().find('.dropdown-menu');
      // eslint-disable-next-line no-jquery/no-fade
      const $loading = $block.find('.block-loading').fadeOut();
      const fieldName = $dropdown.data('fieldName');
      let initialSelected = $selectbox
        .find(`input[name="${$dropdown.data('fieldName')}"]`)
        .map(function() {
          return this.value;
        })
        .get();
      const scopedLabels = $dropdown.data('scopedLabels');
      const scopedLabelsDocumentationLink = $dropdown.data('scopedLabelsDocumentationLink');
      const { handleClick } = options;
      $sidebarLabelTooltip.tooltip();

      if ($dropdown.closest('.dropdown').find('.dropdown-new-label').length) {
        new CreateLabelDropdown(
          $dropdown.closest('.dropdown').find('.dropdown-new-label'),
          namespacePath,
          projectPath,
        );
      }

      const saveLabelData = function() {
        const selected = $dropdown
          .closest('.selectbox')
          .find(`input[name='${fieldName}']`)
          .map(function() {
            return this.value;
          })
          .get();

        if (_.isEqual(initialSelected, selected)) return;
        initialSelected = selected;

        const data = {};
        data[abilityName] = {};
        data[abilityName].label_ids = selected;
        if (!selected.length) {
          data[abilityName].label_ids = [''];
        }
        // eslint-disable-next-line no-jquery/no-fade
        $loading.removeClass('hidden').fadeIn();
        $dropdown.trigger('loading.gl.dropdown');
        axios
          .put(issueUpdateURL, data)
          .then(({ data }) => {
            let labelTooltipTitle;
            let template;
            // eslint-disable-next-line no-jquery/no-fade
            $loading.fadeOut();
            $dropdown.trigger('loaded.gl.dropdown');
            $selectbox.hide();
            data.issueUpdateURL = issueUpdateURL;
            let labelCount = 0;
            if (data.labels.length && issueUpdateURL) {
              template = LabelsSelect.getLabelTemplate({
                labels: _.sortBy(data.labels, 'title'),
                issueUpdateURL,
                enableScopedLabels: scopedLabels,
                scopedLabelsDocumentationLink,
              });
              labelCount = data.labels.length;

              // EE Specific
              if (IS_EE) {
                /**
                 * For Scoped labels, the last label selected with the
                 * same key will be applied to the current issueable.
                 *
                 * If these are the labels - priority::1, priority::2; and if
                 * we apply them in the same order, only priority::2 will stick
                 * with the issuable.
                 *
                 * In the current dropdown implementation, we keep track of all
                 * the labels selected via a hidden DOM element. Since a User
                 * can select priority::1 and priority::2 at the same time, the
                 * DOM will have 2 hidden input and the dropdown will show both
                 * the items selected but in reality server only applied
                 * priority::2.
                 *
                 * We find all the labels then find all the labels server accepted
                 * and then remove the excess ones.
                 */
                const toRemoveIds = Array.from(
                  $form.find(`input[type="hidden"][name="${fieldName}"]`),
                )
                  .map(el => el.value)
                  .map(Number);

                data.labels.forEach(label => {
                  const index = toRemoveIds.indexOf(label.id);
                  toRemoveIds.splice(index, 1);
                });

                toRemoveIds.forEach(id => {
                  $form
                    .find(`input[type="hidden"][name="${fieldName}"][value="${id}"]`)
                    .last()
                    .remove();
                });
              }
            } else {
              template = `<span class="no-value">${__('None')}</span>`;
            }
            $value.removeAttr('style').html(template);
            $sidebarCollapsedValue.text(labelCount);

            if (data.labels.length) {
              let labelTitles = data.labels.map(label => label.title);

              if (labelTitles.length > 5) {
                labelTitles = labelTitles.slice(0, 5);
                labelTitles.push(
                  sprintf(s__('Labels|and %{count} more'), { count: data.labels.length - 5 }),
                );
              }

              labelTooltipTitle = labelTitles.join(', ');
            } else {
              labelTooltipTitle = __('Labels');
            }

            $sidebarLabelTooltip.attr('title', labelTooltipTitle).tooltip('_fixTitle');

            $('.has-tooltip', $value).tooltip({
              container: 'body',
            });
          })
          .catch(() => flash(__('Error saving label update.')));
      };
      $dropdown.glDropdown({
        showMenuAbove,
        data(term, callback) {
          const labelUrl = $dropdown.attr('data-labels');
          axios
            .get(labelUrl)
            .then(res => {
              let { data } = res;
              if ($dropdown.hasClass('js-extra-options')) {
                const extraData = [];
                if (showNo) {
                  extraData.unshift({
                    id: 0,
                    title: __('No Label'),
                  });
                }
                if (showAny) {
                  extraData.unshift({
                    isAny: true,
                    title: __('Any Label'),
                  });
                }
                if (extraData.length) {
                  extraData.push({ type: 'divider' });
                  data = extraData.concat(data);
                }
              }

              callback(data);
              if (showMenuAbove) {
                $dropdown.data('glDropdown').positionMenuAbove();
              }
            })
            .catch(() => flash(__('Error fetching labels.')));
        },
        renderRow(label) {
          let colorEl;

          const selectedClass = [];
          const removesAll = label.id <= 0 || label.id == null;

          if ($dropdown.hasClass('js-filter-bulk-update')) {
            const indeterminate = $dropdown.data('indeterminate') || [];
            const marked = $dropdown.data('marked') || [];

            if (indeterminate.indexOf(label.id) !== -1) {
              selectedClass.push('is-indeterminate');
            }

            if (marked.indexOf(label.id) !== -1) {
              // Remove is-indeterminate class if the item will be marked as active
              const i = selectedClass.indexOf('is-indeterminate');
              if (i !== -1) {
                selectedClass.splice(i, 1);
              }
              selectedClass.push('is-active');
            }
          } else {
            if (this.id(label)) {
              const dropdownValue = this.id(label)
                .toString()
                .replace(/'/g, "\\'");

              if (
                $form.find(
                  `input[type='hidden'][name='${this.fieldName}'][value='${dropdownValue}']`,
                ).length
              ) {
                selectedClass.push('is-active');
              }
            }

            if (this.multiSelect && removesAll) {
              selectedClass.push('dropdown-clear-active');
            }
          }

          if (label.color) {
            colorEl = `<span class='dropdown-label-box' style='background: ${label.color}'></span>`;
          } else {
            colorEl = '';
          }

          const linkEl = document.createElement('a');
          linkEl.href = '#';

          // We need to identify which items are actually labels
          if (label.id) {
            const selectedLayoutClasses = ['d-flex', 'flex-row', 'text-break-word'];
            selectedClass.push('label-item', ...selectedLayoutClasses);
            linkEl.dataset.labelId = label.id;
          }

          linkEl.className = selectedClass.join(' ');
          linkEl.innerHTML = `${colorEl} ${_.escape(label.title)}`;

          const listItemEl = document.createElement('li');
          listItemEl.appendChild(linkEl);

          return listItemEl;
        },
        search: {
          fields: ['title'],
        },
        selectable: true,
        filterable: true,
        selected: $dropdown.data('selected') || [],
        toggleLabel(selected, el) {
          const $dropdownParent = $dropdown.parent();
          const $dropdownInputField = $dropdownParent.find('.dropdown-input-field');
          const isSelected = el !== null ? el.hasClass('is-active') : false;

          const title = selected ? selected.title : null;
          const selectedLabels = this.selected;

          if ($dropdownInputField.length && $dropdownInputField.val().length) {
            $dropdownParent.find('.dropdown-input-clear').trigger('click');
          }

          if (selected && selected.id === 0) {
            this.selected = [];
            return __('No Label');
          } else if (isSelected) {
            this.selected.push(title);
          } else if (!isSelected && title) {
            const index = this.selected.indexOf(title);
            this.selected.splice(index, 1);
          }

          if (selectedLabels.length === 1) {
            return selectedLabels;
          } else if (selectedLabels.length) {
            return sprintf(__('%{firstLabel} +%{labelCount} more'), {
              firstLabel: selectedLabels[0],
              labelCount: selectedLabels.length - 1,
            });
          } else {
            return defaultLabel;
          }
        },
        fieldName: $dropdown.data('fieldName'),
        id(label) {
          if (label.id <= 0) return label.title;

          if ($dropdown.hasClass('js-issuable-form-dropdown')) {
            return label.id;
          }

          if ($dropdown.hasClass('js-filter-submit') && label.isAny == null) {
            return label.title;
          } else {
            return label.id;
          }
        },
        hidden() {
          const page = $('body').attr('data-page');
          const isIssueIndex = page === 'projects:issues:index';
          const isMRIndex = page === 'projects:merge_requests:index';
          $selectbox.hide();
          // display:block overrides the hide-collapse rule
          $value.removeAttr('style');

          if ($dropdown.hasClass('js-issuable-form-dropdown')) {
            return;
          }

          if ($('html').hasClass('issue-boards-page')) {
            return;
          }
          if ($dropdown.hasClass('js-multiselect')) {
            if ($dropdown.hasClass('js-filter-submit') && (isIssueIndex || isMRIndex)) {
              Issuable.filterResults($dropdown.closest('form'));
            } else if ($dropdown.hasClass('js-filter-submit')) {
              $dropdown.closest('form').submit();
            } else {
              if (!$dropdown.hasClass('js-filter-bulk-update')) {
                saveLabelData();
                $dropdown.data('glDropdown').clearMenu();
              }
            }
          }
        },
        multiSelect: $dropdown.hasClass('js-multiselect'),
        vue: $dropdown.hasClass('js-issue-board-sidebar'),
        clicked(clickEvent) {
          const { $el, e, isMarking } = clickEvent;
          const label = clickEvent.selectedObj;

          const fadeOutLoader = () => {
            // eslint-disable-next-line no-jquery/no-fade
            $loading.fadeOut();
          };

          const page = $('body').attr('data-page');
          const isIssueIndex = page === 'projects:issues:index';
          const isMRIndex = page === 'projects:merge_requests:index';

          if ($dropdown.parent().find('.is-active:not(.dropdown-clear-active)').length) {
            $dropdown
              .parent()
              .find('.dropdown-clear-active')
              .removeClass('is-active');
          }

          if ($dropdown.hasClass('js-issuable-form-dropdown')) {
            return;
          }

          if ($dropdown.hasClass('js-filter-bulk-update')) {
            _this.enableBulkLabelDropdown();
            _this.setDropdownData($dropdown, isMarking, label.id);
            return;
          }

          let boardsModel;
          if ($dropdown.closest('.add-issues-modal').length) {
            boardsModel = ModalStore.store.filter;
          }

          if (boardsModel) {
            if (label.isAny) {
              boardsModel['label_name'] = [];
            } else if ($el.hasClass('is-active')) {
              boardsModel['label_name'].push(label.title);
            }

            e.preventDefault();
            return;
          } else if ($dropdown.hasClass('js-filter-submit') && (isIssueIndex || isMRIndex)) {
            if (!$dropdown.hasClass('js-multiselect')) {
              selectedLabel = label.title;
              return Issuable.filterResults($dropdown.closest('form'));
            }
          } else if ($dropdown.hasClass('js-filter-submit')) {
            return $dropdown.closest('form').submit();
          } else if ($dropdown.hasClass('js-issue-board-sidebar')) {
            if ($el.hasClass('is-active')) {
              boardsStore.detail.issue.labels.push(
                new ListLabel({
                  id: label.id,
                  title: label.title,
                  color: label.color,
                  textColor: '#fff',
                }),
              );
            } else {
              let { labels } = boardsStore.detail.issue;
              labels = labels.filter(selectedLabel => selectedLabel.id !== label.id);
              boardsStore.detail.issue.labels = labels;
            }

            // eslint-disable-next-line no-jquery/no-fade
            $loading.fadeIn();
            const oldLabels = boardsStore.detail.issue.labels;

            boardsStore.detail.issue
              .update($dropdown.attr('data-issue-update'))
              .then(() => {
                if (isScopedLabel(label)) {
                  const prevIds = oldLabels.map(label => label.id);
                  const newIds = boardsStore.detail.issue.labels.map(label => label.id);
                  const differentIds = _.difference(prevIds, newIds);
                  $dropdown.data('marked', newIds);
                  $dropdownMenu
                    .find(differentIds.map(id => `[data-label-id="${id}"]`).join(','))
                    .removeClass('is-active');
                }
              })
              .then(fadeOutLoader)
              .catch(fadeOutLoader);
          } else if (handleClick) {
            e.preventDefault();
            handleClick(label);
          } else {
            if ($dropdown.hasClass('js-multiselect')) {
            } else {
              return saveLabelData();
            }
          }
        },
        opened() {
          if ($dropdown.hasClass('js-issue-board-sidebar')) {
            const previousSelection = $dropdown.attr('data-selected');
            this.selected = previousSelection ? previousSelection.split(',') : [];
            $dropdown.data('glDropdown').updateLabel();
          }
        },
        preserveContext: true,
      });

      // Set dropdown data
      _this.setOriginalDropdownData($dropdownContainer, $dropdown);
    });
    this.bindEvents();
  }

  static getLabelTemplate(tplData) {
    // We could use ES6 template string here
    // and properly indent markup for readability
    // but that also introduces unintended white-space
    // so best approach is to use traditional way of
    // concatenation
    // see: http://2ality.com/2016/05/template-literal-whitespace.html#joining-arrays

    const labelTemplate = _.template(
      [
        '<a href="<%- issueUpdateURL.slice(0, issueUpdateURL.lastIndexOf("/")) %>?label_name[]=<%- encodeURIComponent(label.title) %>">',
        '<span class="badge label has-tooltip color-label" <%= linkAttrs %> title="<%= tooltipTitleTemplate({ label, isScopedLabel, enableScopedLabels, escapeStr }) %>" style="background-color: <%= escapeStr(label.color) %>; color: <%= escapeStr(label.text_color) %>;">',
        '<%- label.title %>',
        '</span>',
        '</a>',
      ].join(''),
    );

    const infoIconTemplate = _.template(
      [
        '<a href="<%= scopedLabelsDocumentationLink %>" class="label scoped-label" target="_blank" rel="noopener">',
        '<i class="fa fa-question-circle" style="background-color: <%= escapeStr(label.color) %>; color: <%= escapeStr(label.text_color) %>;"></i>',
        '</a>',
      ].join(''),
    );

    const tooltipTitleTemplate = _.template(
      [
        '<% if (isScopedLabel(label) && enableScopedLabels) { %>',
        "<span class='font-weight-bold scoped-label-tooltip-title'>Scoped label</span>",
        '<br />',
        '<%= escapeStr(label.description) %>',
        '<% } else { %>',
        '<%= escapeStr(label.description) %>',
        '<% } %>',
      ].join(''),
    );

    const tpl = _.template(
      [
        '<% _.each(labels, function(label){ %>',
        '<% if (isScopedLabel(label) && enableScopedLabels) { %>',
        '<span class="d-inline-block position-relative scoped-label-wrapper">',
        '<%= labelTemplate({ label, issueUpdateURL, isScopedLabel, enableScopedLabels, tooltipTitleTemplate, escapeStr, linkAttrs: \'data-html="true"\' }) %>',
        '<%= infoIconTemplate({ label, scopedLabelsDocumentationLink, escapeStr }) %>',
        '</span>',
        '<% } else { %>',
        '<%= labelTemplate({ label, issueUpdateURL, isScopedLabel, enableScopedLabels, tooltipTitleTemplate, escapeStr, linkAttrs: "" }) %>',
        '<% } %>',
        '<% }); %>',
      ].join(''),
    );

    return tpl({
      ...tplData,
      labelTemplate,
      infoIconTemplate,
      tooltipTitleTemplate,
      isScopedLabel,
      escapeStr: _.escape,
    });
  }

  bindEvents() {
    return $('body').on('change', '.selected-issuable', this.onSelectCheckboxIssue);
  }
  // eslint-disable-next-line class-methods-use-this
  onSelectCheckboxIssue() {
    if ($('.selected-issuable:checked').length) {
      return;
    }
    return $('.issues-bulk-update .labels-filter .dropdown-toggle-text').text(__('Label'));
  }
  // eslint-disable-next-line class-methods-use-this
  enableBulkLabelDropdown() {
    IssuableBulkUpdateActions.willUpdateLabels = true;
  }
  // eslint-disable-next-line class-methods-use-this
  setDropdownData($dropdown, isMarking, value) {
    const markedIds = $dropdown.data('marked') || [];
    const unmarkedIds = $dropdown.data('unmarked') || [];
    const indeterminateIds = $dropdown.data('indeterminate') || [];

    if (isMarking) {
      markedIds.push(value);

      let i = indeterminateIds.indexOf(value);
      if (i > -1) {
        indeterminateIds.splice(i, 1);
      }

      i = unmarkedIds.indexOf(value);
      if (i > -1) {
        unmarkedIds.splice(i, 1);
      }
    } else {
      // If marked item (not common) is unmarked
      const i = markedIds.indexOf(value);
      if (i > -1) {
        markedIds.splice(i, 1);
      }

      // If an indeterminate item is being unmarked
      if (IssuableBulkUpdateActions.getOriginalIndeterminateIds().indexOf(value) > -1) {
        unmarkedIds.push(value);
      }

      // If a marked item is being unmarked
      // (a marked item could also be a label that is present in all selection)
      if (IssuableBulkUpdateActions.getOriginalCommonIds().indexOf(value) > -1) {
        unmarkedIds.push(value);
      }
    }

    $dropdown.data('marked', markedIds);
    $dropdown.data('unmarked', unmarkedIds);
    $dropdown.data('indeterminate', indeterminateIds);
  }
  // eslint-disable-next-line class-methods-use-this
  setOriginalDropdownData($container, $dropdown) {
    const labels = [];
    $container.find('[name="label_name[]"]').map(function() {
      return labels.push(this.value);
    });
    $dropdown.data('marked', labels);
  }
}
