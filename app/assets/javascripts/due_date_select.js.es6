/* eslint-disable wrap-iife, func-names, space-before-function-paren, comma-dangle, prefer-template, consistent-return, class-methods-use-this, arrow-body-style, prefer-const, padded-blocks, no-unused-vars, no-underscore-dangle, no-new, max-len, semi, no-sequences, no-unused-expressions, no-param-reassign */

(function(global) {
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
      this.issueUpdateURL = $dropdown.data('issue-update')

      this.rawSelectedDate = null;
      this.displayedDate = null;
      this.datePayload = null;

      this.initGlDropdown();
      this.initRemoveDueDate();
      this.initDatePicker();
      this.initStopPropagation();
    }

    initGlDropdown() {
      this.$dropdown.glDropdown({
        hidden: () => {
          this.$selectbox.hide();
          this.$value.css('display', '');
        }
      });
    }

    initDatePicker() {
      this.$datePicker.datepicker({
        dateFormat: 'yy-mm-dd',
        defaultDate: $("input[name='" + this.fieldName + "']").val(),
        altField: "input[name='" + this.fieldName + "']",
        onSelect: () => {
          if (this.$dropdown.hasClass('js-issue-boards-due-date')) {
            gl.issueBoards.BoardsStore.detail.issue.dueDate = $(`input[name='${this.fieldName}']`).val();
            this.updateIssueBoardIssue();
          } else {
            return this.saveDueDate(true);
          }
        }
      });
    }

    initRemoveDueDate() {
      this.$block.on('click', '.js-remove-due-date', (e) => {
        e.preventDefault();

        if (this.$dropdown.hasClass('js-issue-boards-due-date')) {
          gl.issueBoards.BoardsStore.detail.issue.dueDate = '';
          this.updateIssueBoardIssue();
        } else {
          $("input[name='" + this.fieldName + "']").val('');
          return this.saveDueDate(false);
        }
      });
    }

    initStopPropagation() {
      $(document).off('click', '.ui-datepicker-header a').on('click', '.ui-datepicker-header a', (e) => {
        return e.stopImmediatePropagation();
      });
    }

    saveDueDate(isDropdown) {
      this.parseSelectedDate();
      this.prepSelectedDate();
      this.submitSelectedDate(isDropdown);
    }

    parseSelectedDate() {
      this.rawSelectedDate = $("input[name='" + this.fieldName + "']").val();
      if (this.rawSelectedDate.length) {
        let dateObj = new Date(this.rawSelectedDate);
        this.displayedDate = $.datepicker.formatDate('M d, yy', dateObj);
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

      gl.issueBoards.BoardsStore.detail.issue.update(this.$dropdown.attr('data-issue-update'))
        .then(() => {
          this.$loading.fadeOut();
        });
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

          this.$loading.fadeIn();

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
      $('.datepicker').datepicker({
        dateFormat: 'yy-mm-dd'
      });

      $('.js-clear-due-date,.js-clear-start-date').on('click', (e) => {
        e.preventDefault();
        const datepicker = $(e.target).siblings('.datepicker');
        $.datepicker._clearDate(datepicker);
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

  global.DueDateSelectors = DueDateSelectors;

})(window.gl || (window.gl = {}));
