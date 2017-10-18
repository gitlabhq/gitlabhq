/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, no-use-before-define, no-useless-escape, no-new, quotes, object-shorthand, no-unused-vars, comma-dangle, no-alert, consistent-return, no-else-return, prefer-template, one-var, one-var-declaration-per-line, curly, max-len */
/* global GitLab */
/* global Autosave */
/* global GroupsSelect */

import Pikaday from 'pikaday';
import UsersSelect from './users_select';
import GfmAutoComplete from './gfm_auto_complete';
import ZenMode from './zen_mode';
import { parsePikadayDate, pikadayToString } from './lib/utils/datefix';

(function() {
  this.IssuableForm = (function() {
    IssuableForm.prototype.wipRegex = /^\s*(\[WIP\]\s*|WIP:\s*|WIP\s+)+\s*/i;

    function IssuableForm(form) {
      var $issuableDueDate, calendar;
      this.form = form;
      this.toggleWip = this.toggleWip.bind(this);
      this.renderWipExplanation = this.renderWipExplanation.bind(this);
      this.resetAutosave = this.resetAutosave.bind(this);
      this.handleSubmit = this.handleSubmit.bind(this);
      new GfmAutoComplete(gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources).setup();
      new UsersSelect();
      new GroupsSelect();
      new ZenMode();
      this.titleField = this.form.find("input[name*='[title]']");
      this.descriptionField = this.form.find("textarea[name*='[description]']");
      if (!(this.titleField.length && this.descriptionField.length)) {
        return;
      }
      this.initAutosave();
      this.form.on("submit", this.handleSubmit);
      this.form.on("click", ".btn-cancel", this.resetAutosave);
      this.initWip();
      $issuableDueDate = $('#issuable-due-date');
      if ($issuableDueDate.length) {
        calendar = new Pikaday({
          field: $issuableDueDate.get(0),
          theme: 'gitlab-theme animate-picker',
          format: 'yyyy-mm-dd',
          container: $issuableDueDate.parent().get(0),
          parse: dateString => parsePikadayDate(dateString),
          toString: date => pikadayToString(date),
          onSelect: function(dateText) {
            $issuableDueDate.val(calendar.toString(dateText));
          }
        });
        calendar.setDate(parsePikadayDate($issuableDueDate.val()));
      }
    }

    IssuableForm.prototype.initAutosave = function() {
      new Autosave(this.titleField, [document.location.pathname, document.location.search, "title"]);
      return new Autosave(this.descriptionField, [document.location.pathname, document.location.search, "description"]);
    };

    IssuableForm.prototype.handleSubmit = function() {
      return this.resetAutosave();
    };

    IssuableForm.prototype.resetAutosave = function() {
      this.titleField.data("autosave").reset();
      return this.descriptionField.data("autosave").reset();
    };

    IssuableForm.prototype.initWip = function() {
      this.$wipExplanation = this.form.find(".js-wip-explanation");
      this.$noWipExplanation = this.form.find(".js-no-wip-explanation");
      if (!(this.$wipExplanation.length && this.$noWipExplanation.length)) {
        return;
      }
      this.form.on("click", ".js-toggle-wip", this.toggleWip);
      this.titleField.on("keyup blur", this.renderWipExplanation);
      return this.renderWipExplanation();
    };

    IssuableForm.prototype.workInProgress = function() {
      return this.wipRegex.test(this.titleField.val());
    };

    IssuableForm.prototype.renderWipExplanation = function() {
      if (this.workInProgress()) {
        this.$wipExplanation.show();
        return this.$noWipExplanation.hide();
      } else {
        this.$wipExplanation.hide();
        return this.$noWipExplanation.show();
      }
    };

    IssuableForm.prototype.toggleWip = function(event) {
      event.preventDefault();
      if (this.workInProgress()) {
        this.removeWip();
      } else {
        this.addWip();
      }
      return this.renderWipExplanation();
    };

    IssuableForm.prototype.removeWip = function() {
      return this.titleField.val(this.titleField.val().replace(this.wipRegex, ""));
    };

    IssuableForm.prototype.addWip = function() {
      return this.titleField.val("WIP: " + (this.titleField.val()));
    };

    return IssuableForm;
  })();
}).call(window);
