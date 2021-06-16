import $ from 'jquery';
import Pikaday from 'pikaday';
import GfmAutoComplete from 'ee_else_ce/gfm_auto_complete';
import Autosave from './autosave';
import AutoWidthDropdownSelect from './issuable/auto_width_dropdown_select';
import { loadCSSFile } from './lib/utils/css_utils';
import { parsePikadayDate, pikadayToString } from './lib/utils/datetime_utility';
import { select2AxiosTransport } from './lib/utils/select2_utils';
import { queryToObject, objectToQuery } from './lib/utils/url_utility';
import UsersSelect from './users_select';
import ZenMode from './zen_mode';

const MR_SOURCE_BRANCH = 'merge_request[source_branch]';
const MR_TARGET_BRANCH = 'merge_request[target_branch]';

function organizeQuery(obj, isFallbackKey = false) {
  if (!obj[MR_SOURCE_BRANCH] && !obj[MR_TARGET_BRANCH]) {
    return obj;
  }

  if (isFallbackKey) {
    return {
      [MR_SOURCE_BRANCH]: obj[MR_SOURCE_BRANCH],
    };
  }

  return {
    [MR_SOURCE_BRANCH]: obj[MR_SOURCE_BRANCH],
    [MR_TARGET_BRANCH]: obj[MR_TARGET_BRANCH],
  };
}

function format(searchTerm, isFallbackKey = false) {
  const queryObject = queryToObject(searchTerm, { legacySpacesDecode: true });
  const organizeQueryObject = organizeQuery(queryObject, isFallbackKey);
  const formattedQuery = objectToQuery(organizeQueryObject);

  return formattedQuery;
}

function getFallbackKey() {
  const searchTerm = format(document.location.search, true);
  return ['autosave', document.location.pathname, searchTerm].join('/');
}

export default class IssuableForm {
  constructor(form) {
    this.form = form;
    this.toggleWip = this.toggleWip.bind(this);
    this.renderWipExplanation = this.renderWipExplanation.bind(this);
    this.resetAutosave = this.resetAutosave.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    /* eslint-disable @gitlab/require-i18n-strings */
    this.wipRegex = new RegExp(
      '^\\s*(' + // Line start, then any amount of leading whitespace
        'draft\\s-\\s' + // Draft_-_ where "_" are *exactly* one whitespace
        '|\\[draft\\]\\s*' + // [Draft] or [WIP] and any following whitespace
        '|draft:\\s*' + // Draft: or WIP: and any following whitespace
        '|draft\\s+' + // Draft_ or WIP_ where "_" is at least one whitespace
        '|\\(draft\\)\\s*' + // (Draft) and any following whitespace
        ')+' + // At least one repeated match of the preceding parenthetical
        '\\s*', // Any amount of trailing whitespace
      'i', // Match any case(s)
    );
    /* eslint-enable @gitlab/require-i18n-strings */

    this.gfmAutoComplete = new GfmAutoComplete(
      gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources,
    ).setup();
    this.usersSelect = new UsersSelect();
    this.reviewersSelect = new UsersSelect(undefined, '.js-reviewer-search');
    this.zenMode = new ZenMode();

    this.titleField = this.form.find('input[name*="[title]"]');
    this.descriptionField = this.form.find('textarea[name*="[description]"]');
    if (!(this.titleField.length && this.descriptionField.length)) {
      return;
    }

    this.initAutosave();
    this.form.on('submit', this.handleSubmit);
    this.form.on('click', '.btn-cancel', this.resetAutosave);
    this.initWip();

    const $issuableDueDate = $('#issuable-due-date');

    if ($issuableDueDate.length) {
      const calendar = new Pikaday({
        field: $issuableDueDate.get(0),
        theme: 'gitlab-theme animate-picker',
        format: 'yyyy-mm-dd',
        container: $issuableDueDate.parent().get(0),
        parse: (dateString) => parsePikadayDate(dateString),
        toString: (date) => pikadayToString(date),
        onSelect: (dateText) => $issuableDueDate.val(calendar.toString(dateText)),
        firstDay: gon.first_day_of_week,
      });
      calendar.setDate(parsePikadayDate($issuableDueDate.val()));
    }

    this.$targetBranchSelect = $('.js-target-branch-select', this.form);

    if (this.$targetBranchSelect.length) {
      this.initTargetBranchDropdown();
    }
  }

  initAutosave() {
    const { search } = document.location;
    const searchTerm = format(search);
    const fallbackKey = getFallbackKey();

    this.autosave = new Autosave(
      this.titleField,
      [document.location.pathname, searchTerm, 'title'],
      `${fallbackKey}=title`,
    );

    return new Autosave(
      this.descriptionField,
      [document.location.pathname, searchTerm, 'description'],
      `${fallbackKey}=description`,
    );
  }

  handleSubmit() {
    return this.resetAutosave();
  }

  resetAutosave() {
    this.titleField.data('autosave').reset();
    return this.descriptionField.data('autosave').reset();
  }

  initWip() {
    this.$wipExplanation = this.form.find('.js-wip-explanation');
    this.$noWipExplanation = this.form.find('.js-no-wip-explanation');
    if (!(this.$wipExplanation.length && this.$noWipExplanation.length)) {
      return undefined;
    }
    this.form.on('click', '.js-toggle-wip', this.toggleWip);
    this.titleField.on('keyup blur', this.renderWipExplanation);
    return this.renderWipExplanation();
  }

  workInProgress() {
    return this.wipRegex.test(this.titleField.val());
  }

  renderWipExplanation() {
    if (this.workInProgress()) {
      // These strings are not "translatable" (the code is hard-coded to look for them)
      this.$wipExplanation.find('code')[0].textContent =
        'Draft'; /* eslint-disable-line @gitlab/require-i18n-strings */
      this.$wipExplanation.show();
      return this.$noWipExplanation.hide();
    }
    this.$wipExplanation.hide();
    return this.$noWipExplanation.show();
  }

  toggleWip(event) {
    event.preventDefault();
    if (this.workInProgress()) {
      this.removeWip();
    } else {
      this.addWip();
    }
    return this.renderWipExplanation();
  }

  removeWip() {
    return this.titleField.val(this.titleField.val().replace(this.wipRegex, ''));
  }

  addWip() {
    this.titleField.val(`Draft: ${this.titleField.val()}`);
  }

  initTargetBranchDropdown() {
    import(/* webpackChunkName: 'select2' */ 'select2/select2')
      .then(() => {
        // eslint-disable-next-line promise/no-nesting
        loadCSSFile(gon.select2_css_path)
          .then(() => {
            this.$targetBranchSelect.select2({
              ...AutoWidthDropdownSelect.selectOptions('js-target-branch-select'),
              ajax: {
                url: this.$targetBranchSelect.data('endpoint'),
                dataType: 'JSON',
                quietMillis: 250,
                data(search) {
                  return {
                    search,
                  };
                },
                results({ results }) {
                  return {
                    // `data` keys are translated so we can't just access them with a string based key
                    results: results[Object.keys(results)[0]].map((name) => ({
                      id: name,
                      text: name,
                    })),
                  };
                },
                transport: select2AxiosTransport,
              },
              initSelection(el, callback) {
                const val = el.val();

                callback({
                  id: val,
                  text: val,
                });
              },
            });
          })
          .catch(() => {});
      })
      .catch(() => {});
  }
}
