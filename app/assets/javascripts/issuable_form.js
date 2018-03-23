/* eslint-disable func-names, prefer-rest-params, wrap-iife, no-use-before-define, no-useless-escape, no-new, object-shorthand, no-unused-vars, comma-dangle, no-alert, consistent-return, no-else-return, prefer-template, one-var, one-var-declaration-per-line, curly, max-len */
/* global GitLab */

import $ from 'jquery';
import Pikaday from 'pikaday';
import Autosave from './autosave';
import UsersSelect from './users_select';
import GfmAutoComplete from './gfm_auto_complete';
import ZenMode from './zen_mode';
import AutoWidthDropdownSelect from './issuable/auto_width_dropdown_select';
import { parsePikadayDate, pikadayToString } from './lib/utils/datefix';

export default class IssuableForm {
  constructor(form) {
    this.form = form;
    this.toggleWip = this.toggleWip.bind(this);
    this.renderWipExplanation = this.renderWipExplanation.bind(this);
    this.resetAutosave = this.resetAutosave.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
    this.wipRegex = /^\s*(\[WIP\]\s*|WIP:\s*|WIP\s+)+\s*/i;

    new GfmAutoComplete(gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources).setup();
    new UsersSelect();
    new ZenMode();

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
        parse: dateString => parsePikadayDate(dateString),
        toString: date => pikadayToString(date),
        onSelect: dateText => $issuableDueDate.val(calendar.toString(dateText)),
      });
      calendar.setDate(parsePikadayDate($issuableDueDate.val()));
    }

    this.$targetBranchSelect = $('.js-target-branch-select', this.form);

    if (this.$targetBranchSelect.length) {
      this.initTargetBranchDropdown();
    }
  }

  initAutosave() {
    new Autosave(this.titleField, [document.location.pathname, document.location.search, 'title']);
    return new Autosave(this.descriptionField, [document.location.pathname, document.location.search, 'description']);
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
      return;
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
      this.$wipExplanation.show();
      return this.$noWipExplanation.hide();
    } else {
      this.$wipExplanation.hide();
      return this.$noWipExplanation.show();
    }
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
    this.titleField.val(`WIP: ${(this.titleField.val())}`);
  }

  initTargetBranchDropdown() {
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
        results(data) {
          return {
            // `data` keys are translated so we can't just access them with a string based key
            results: data[Object.keys(data)[0]].map(name => ({
              id: name,
              text: name,
            })),
          };
        },
      },
      initSelection(el, callback) {
        const val = el.val();

        callback({
          id: val,
          text: val,
        });
      },
    });
  }
}
