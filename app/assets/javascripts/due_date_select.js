/* eslint-disable wrap-iife, func-names, space-before-function-paren, comma-dangle, prefer-template, consistent-return, class-methods-use-this, arrow-body-style, no-unused-vars, no-underscore-dangle, no-new, max-len, no-sequences, no-unused-expressions, no-param-reassign */
/* global dateFormat */
/* global Pikaday */

import DateFix from './lib/utils/datefix';

class DueDateSelect {
  constructor({ $dropdown, $loading } = {}) {
    const $dropdownParent = $dropdown.closest('.dropdown');
    const $block = $dropdown.closest('.block');
    this.$loading = $loading;
    this.$dropdown = $dropdown;
    this.$dropdownParent = $dropdownParent;
    this.$datePicker = $dropdownParent.find('.js-due-date-calendar');
    this.$block = $block;
    this.$selectbox = $dropdown.closest('.selectbox');
    this.$value = $block.find('.value');
    this.$valueContent = $block.find('.value-content');
    this.$sidebarValue = $('.js-due-date-sidebar-value', $block);
    this.fieldName = $dropdown.data('field-name'),
    this.abilityName = $dropdown.data('ability-name'),
    this.issueUpdateURL = $dropdown.data('issue-update');

    this.rawSelectedDate = null;
    this.displayedDate = null;
    this.datePayload = null;

    this.initGlDropdown();
    this.initRemoveDueDate();
    this.initDatePicker();
  }

  initGlDropdown() {
    this.$dropdown.glDropdown({
      opened: () => {
        const calendar = this.$datePicker.data('pikaday');
        calendar.show();
      },
      hidden: () => {
        this.$selectbox.hide();
        this.$value.css('display', '');
      }
    });
  }

  initDatePicker() {
    const $dueDateInput = $(`input[name='${this.fieldName}']`);
    const dateFix = DateFix.dashedFix($dueDateInput.val());
    const calendar = new Pikaday({
      field: $dueDateInput.get(0),
      theme: 'gitlab-theme',
      format: 'yyyy-mm-dd',
      onSelect: (dateText) => {
        const formattedDate = dateFormat(new Date(dateText), 'yyyy-mm-dd');
        $dueDateInput.val(formattedDate);

        if (this.$dropdown.hasClass('js-issue-boards-due-date')) {
          gl.issueBoards.BoardsStore.detail.issue.dueDate = $dueDateInput.val();
          this.updateIssueBoardIssue();
        } else {
          this.saveDueDate(true);
        }
      }
    });

    calendar.setDate(dateFix);
    this.$datePicker.append(calendar.el);
    this.$datePicker.data('pikaday', calendar);
  }

  initRemoveDueDate() {
    this.$block.on('click', '.js-remove-due-date', (e) => {
      const calendar = this.$datePicker.data('pikaday');
      e.preventDefault();

      calendar.setDate(null);

      if (this.$dropdown.hasClass('js-issue-boards-due-date')) {
        gl.issueBoards.BoardsStore.detail.issue.dueDate = '';
        this.updateIssueBoardIssue();
      } else {
        $("input[name='" + this.fieldName + "']").val('');
        return this.saveDueDate(false);
      }
    });
  }

  saveDueDate(isDropdown) {
    this.parseSelectedDate();
    this.prepSelectedDate();
    this.submitSelectedDate(isDropdown);
  }

  parseSelectedDate() {
    this.rawSelectedDate = $(`input[name='${this.fieldName}']`).val();

    if (this.rawSelectedDate.length) {
      // Construct Date object manually to avoid buggy dateString support within Date constructor
      const dateArray = this.rawSelectedDate.split('-').map(v => parseInt(v, 10));
      const dateObj = new Date(dateArray[0], dateArray[1] - 1, dateArray[2]);
      this.displayedDate = dateFormat(dateObj, 'mmm d, yyyy');
    } else {
      this.displayedDate = 'No due date';
    }
  }

  prepSelectedDate() {
    const datePayload = {};
    datePayload[this.abilityName] = {};
    datePayload[this.abilityName].due_date = this.rawSelectedDate;
    this.datePayload = datePayload;
  }

  updateIssueBoardIssue () {
    this.$loading.fadeIn();
    this.$dropdown.trigger('loading.gl.dropdown');
    this.$selectbox.hide();
    this.$value.css('display', '');
    const fadeOutLoader = () => {
      this.$loading.fadeOut();
    };

    gl.issueBoards.BoardsStore.detail.issue.update(this.$dropdown.attr('data-issue-update'))
      .then(fadeOutLoader)
      .catch(fadeOutLoader);
  }

  submitSelectedDate(isDropdown) {
    return $.ajax({
      type: 'PUT',
      url: this.issueUpdateURL,
      data: this.datePayload,
      dataType: 'json',
      beforeSend: () => {
        const selectedDateValue = this.datePayload[this.abilityName].due_date;
        const displayedDateStyle = this.displayedDate !== 'No due date' ? 'bold' : 'no-value';

        this.$loading.removeClass('hidden').fadeIn();

        if (isDropdown) {
          this.$dropdown.trigger('loading.gl.dropdown');
          this.$selectbox.hide();
        }

        this.$value.css('display', '');
        this.$valueContent.html(`<span class='${displayedDateStyle}'>${this.displayedDate}</span>`);
        this.$sidebarValue.html(this.displayedDate);

        return selectedDateValue.length ?
          $('.js-remove-due-date-holder').removeClass('hidden') :
          $('.js-remove-due-date-holder').addClass('hidden');
      }
    }).done((data) => {
      if (isDropdown) {
        this.$dropdown.trigger('loaded.gl.dropdown');
        this.$dropdown.dropdown('toggle');
      }
      return this.$loading.fadeOut();
    });
  }
}

class DueDateSelectors {
  constructor() {
    this.initMilestoneDatePicker();
    this.initIssuableSelect();
  }

  initMilestoneDatePicker() {
    $('.datepicker').each(function() {
      const $datePicker = $(this);
      const dateFix = DateFix.dashedFix($datePicker.val());
      const calendar = new Pikaday({
        field: $datePicker.get(0),
        theme: 'gitlab-theme animate-picker',
        format: 'yyyy-mm-dd',
        container: $datePicker.parent().get(0),
        onSelect(dateText) {
          $datePicker.val(dateFormat(new Date(dateText), 'yyyy-mm-dd'));
        }
      });

      calendar.setDate(dateFix);

      $datePicker.data('pikaday', calendar);
    });

    $('.js-clear-due-date,.js-clear-start-date').on('click', (e) => {
      e.preventDefault();
      const calendar = $(e.target).siblings('.datepicker').data('pikaday');
      calendar.setDate(null);
    });
  }

  initIssuableSelect() {
    const $loading = $('.js-issuable-update .due_date').find('.block-loading').hide();

    $('.js-due-date-select').each((i, dropdown) => {
      const $dropdown = $(dropdown);
      new DueDateSelect({
        $dropdown,
        $loading
      });
    });
  }
}

window.gl = window.gl || {};
window.gl.DueDateSelectors = DueDateSelectors;
