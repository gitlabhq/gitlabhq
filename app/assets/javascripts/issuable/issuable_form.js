import $ from 'jquery';
import Pikaday from 'pikaday';
import GfmAutoComplete from 'ee_else_ce/gfm_auto_complete';
import Autosave from '~/autosave';
import { newDate, toISODateFormat } from '~/lib/utils/datetime_utility';
import { queryToObject, objectToQuery } from '~/lib/utils/url_utility';
import UsersSelect from '~/users_select';
import ZenMode from '~/zen_mode';
import { detectAndConfirmSensitiveTokens, CONTENT_TYPE } from '~/lib/utils/secret_detection';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';
import { EDITING_MODE_CONTENT_EDITOR } from '~/vue_shared/constants';
import { ISSUE_NOTEABLE_TYPE, MERGE_REQUEST_NOTEABLE_TYPE } from '~/notes/constants';

const MR_SOURCE_BRANCH = 'merge_request[source_branch]';
const MR_TARGET_BRANCH = 'merge_request[target_branch]';
const DATA_ISSUES_NEW_PATH = 'data-new-issue-path';

export function organizeQuery(obj, isFallbackKey = false) {
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

function getSearchTerm(newIssuePath) {
  const { search, pathname } = document.location;
  return newIssuePath === pathname ? '' : format(search);
}

function getFallbackKey() {
  const searchTerm = format(document.location.search, true);
  return ['autosave', document.location.pathname, searchTerm].join('/');
}

function getIssuableType() {
  if (document.location.pathname.includes('merge_requests')) return MERGE_REQUEST_NOTEABLE_TYPE;
  if (document.location.pathname.includes('issues')) return ISSUE_NOTEABLE_TYPE;
  // eslint-disable-next-line @gitlab/require-i18n-strings
  return 'Other';
}

export default class IssuableForm {
  // eslint-disable-next-line max-params
  static addAutosave(map, id, element, searchTerm, fallbackKey) {
    if (!element) return;
    map.set(
      id,
      new Autosave(element, [document.location.pathname, searchTerm, id], `${fallbackKey}=${id}`),
    );
  }

  constructor(form) {
    if (form.length === 0) {
      return;
    }
    this.form = form;
    this.resetAutosave = this.resetAutosave.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    // prettier-ignore
    this.draftRegex = new RegExp(
      '^\\s*(' + // Line start, then any amount of leading whitespace
        '\\[draft\\]\\s*' + // [Draft] and any following whitespace
        '|draft:\\s*' + // Draft: and any following whitespace
        '|\\(draft\\)\\s*' + // (Draft) and any following whitespace
      ')+' + // At least one repeated match of the preceding parenthetical
      '\\s*', // Any amount of trailing whitespace
      'i', // Match any case(s)
    );

    this.gfmAutoComplete = new GfmAutoComplete(
      gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources,
    ).setup();
    this.usersSelect = new UsersSelect();
    this.reviewersSelect = new UsersSelect(undefined, '.js-reviewer-search');
    this.zenMode = new ZenMode();

    this.searchTerm = getSearchTerm(form[0].getAttribute(DATA_ISSUES_NEW_PATH));
    this.fallbackKey = getFallbackKey();
    this.titleField = this.form.find('input[name*="[title]"]');
    this.descriptionField = () => this.form.find('textarea[name*="[description]"]');
    this.submitButton = this.form.find('.js-issuable-submit-button');
    this.draftCheck = document.querySelector('input.js-toggle-draft');
    if (!this.titleField.length) return;

    this.autosaves = this.initAutosave();
    this.form.on('submit', this.handleSubmit);
    this.form.on('click', '.btn-cancel, .js-reset-autosave', this.resetAutosave);
    this.initDraft();

    const $issuableDueDate = $('#issuable-due-date');

    if ($issuableDueDate.length) {
      const calendar = new Pikaday({
        field: $issuableDueDate.get(0),
        theme: 'gl-datepicker-theme animate-picker',
        format: 'yyyy-mm-dd',
        container: $issuableDueDate.parent().get(0),
        parse: (dateString) => newDate(dateString),
        toString: (date) => toISODateFormat(date),
        onSelect: (dateText) => {
          $issuableDueDate.val(calendar.toString(dateText));
          if (this.autosaves.has('due_date')) this.autosaves.get('due_date').save();
        },
        firstDay: gon.first_day_of_week,
      });
      calendar.setDate(newDate($issuableDueDate.val()));
    }
  }

  initAutosave() {
    const autosaveMap = new Map();
    IssuableForm.addAutosave(
      autosaveMap,
      'title',
      this.form.find('input[name*="[title]"]').get(0),
      this.searchTerm,
      this.fallbackKey,
    );
    IssuableForm.addAutosave(
      autosaveMap,
      'confidential',
      this.form.find('input:checkbox[name*="[confidential]"]').get(0),
      this.searchTerm,
      this.fallbackKey,
    );
    IssuableForm.addAutosave(
      autosaveMap,
      'due_date',
      this.form.find('input[name*="[due_date]"]').get(0),
      this.searchTerm,
      this.fallbackKey,
    );

    return autosaveMap;
  }

  async handleSubmit(event) {
    event.preventDefault();

    trackSavedUsingEditor(
      localStorage.getItem('gl-markdown-editor-mode') === EDITING_MODE_CONTENT_EDITOR,
      getIssuableType(),
    );

    const form = event.target;
    const descriptionText = this.descriptionField().val();

    const confirmSubmit = await detectAndConfirmSensitiveTokens({
      content: descriptionText,
      contentType: CONTENT_TYPE.DESCRIPTION,
    });

    if (!confirmSubmit) {
      this.submitButton.removeAttr('disabled');
      this.submitButton.removeClass('disabled');
      return false;
    }

    form.submit();
    return this.resetAutosave();
  }

  resetAutosave() {
    this.autosaves.forEach((autosaveItem) => {
      autosaveItem?.reset();
    });
  }

  initDraft() {
    if (this.draftCheck) {
      this.draftCheck.addEventListener('click', () => this.writeDraftStatus());
      this.titleField.on('keyup blur', () => this.readDraftStatus());

      this.readDraftStatus();
    }
  }

  isMarkedDraft() {
    return this.draftRegex.test(this.titleField.val());
  }
  readDraftStatus() {
    this.draftCheck.checked = this.isMarkedDraft();
  }
  writeDraftStatus() {
    if (this.draftCheck.checked) {
      this.addDraft();
    } else {
      this.removeDraft();
    }
  }

  removeDraft() {
    return this.titleField.val(this.titleField.val().replace(this.draftRegex, ''));
  }

  addDraft() {
    this.titleField.val(`Draft: ${this.titleField.val()}`);
  }
}
