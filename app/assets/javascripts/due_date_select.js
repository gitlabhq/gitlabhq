(function() {
  this.DueDateSelect = (function() {
    function DueDateSelect() {
      var $datePicker, $dueDate, $loading;
      // Milestone edit/new form
      $datePicker = $('.datepicker');
      if ($datePicker.length) {
        $dueDate = $('#milestone_due_date');
        $datePicker.datepicker({
          dateFormat: 'yy-mm-dd',
          onSelect: function(dateText, inst) {
            return $dueDate.val(dateText);
          }
        }).datepicker('setDate', $.datepicker.parseDate('yy-mm-dd', $dueDate.val()));
      }
      $('.js-clear-due-date').on('click', function(e) {
        e.preventDefault();
        return $.datepicker._clearDate($datePicker);
      });
      // Issuable sidebar
      $loading = $('.js-issuable-update .due_date').find('.block-loading').hide();
      $('.js-due-date-select').each(function(i, dropdown) {
        var $block, $dropdown, $dropdownParent, $selectbox, $sidebarValue, $value, $valueContent, abilityName, addDueDate, fieldName, issueUpdateURL;
        $dropdown = $(dropdown);
        $dropdownParent = $dropdown.closest('.dropdown');
        $datePicker = $dropdownParent.find('.js-due-date-calendar');
        $block = $dropdown.closest('.block');
        $selectbox = $dropdown.closest('.selectbox');
        $value = $block.find('.value');
        $valueContent = $block.find('.value-content');
        $sidebarValue = $('.js-due-date-sidebar-value', $block);
        fieldName = $dropdown.data('field-name');
        abilityName = $dropdown.data('ability-name');
        issueUpdateURL = $dropdown.data('issue-update');
        $dropdown.glDropdown({
          hidden: function() {
            $selectbox.hide();
            return $value.css('display', '');
          }
        });
        addDueDate = function(isDropdown) {
          var data, date, mediumDate, value;
          // Create the post date
          value = $("input[name='" + fieldName + "']").val();
          if (value !== '') {
            date = new Date(value.replace(new RegExp('-', 'g'), ','));
            mediumDate = $.datepicker.formatDate('M d, yy', date);
          } else {
            mediumDate = 'No due date';
          }
          data = {};
          data[abilityName] = {};
          data[abilityName].due_date = value;
          return $.ajax({
            type: 'PUT',
            url: issueUpdateURL,
            data: data,
            dataType: 'json',
            beforeSend: function() {
              var cssClass;
              $loading.fadeIn();
              if (isDropdown) {
                $dropdown.trigger('loading.gl.dropdown');
                $selectbox.hide();
              }
              $value.css('display', '');
              cssClass = Date.parse(mediumDate) ? 'bold' : 'no-value';
              $valueContent.html("<span class='" + cssClass + "'>" + mediumDate + "</span>");
              $sidebarValue.html(mediumDate);
              if (value !== '') {
                return $('.js-remove-due-date-holder').removeClass('hidden');
              } else {
                return $('.js-remove-due-date-holder').addClass('hidden');
              }
            }
          }).done(function(data) {
            if (isDropdown) {
              $dropdown.trigger('loaded.gl.dropdown');
              $dropdown.dropdown('toggle');
            }
            return $loading.fadeOut();
          });
        };
        $block.on('click', '.js-remove-due-date', function(e) {
          e.preventDefault();
          $("input[name='" + fieldName + "']").val('');
          return addDueDate(false);
        });
        return $datePicker.datepicker({
          dateFormat: 'yy-mm-dd',
          defaultDate: $("input[name='" + fieldName + "']").val(),
          altField: "input[name='" + fieldName + "']",
          onSelect: function() {
            return addDueDate(true);
          }
        });
      });
      $(document).off('click', '.ui-datepicker-header a').on('click', '.ui-datepicker-header a', function(e) {
        return e.stopImmediatePropagation();
      });
    }

    return DueDateSelect;

  })();

  window.gl.Dispatcher.register([
    'projects:milestones:new',
    'projects:milestones:edit'
  ], this.DueDateSelect);

}).call(this);
