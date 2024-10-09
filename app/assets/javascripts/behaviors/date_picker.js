import $ from 'jquery';
import Pikaday from 'pikaday';
import { newDate, toISODateFormat } from '~/lib/utils/datetime_utility';

export default function initDatePickers() {
  $('.datepicker').each(function initPikaday() {
    const $datePicker = $(this);
    const datePickerVal = $datePicker.val();

    const calendar = new Pikaday({
      field: $datePicker.get(0),
      theme: 'gl-datepicker-theme animate-picker',
      format: 'yyyy-mm-dd',
      container: $datePicker.parent().get(0),
      parse: (dateString) => newDate(dateString),
      toString: (date) => toISODateFormat(date),
      onSelect(dateText) {
        $datePicker.val(calendar.toString(dateText));
      },
      firstDay: gon.first_day_of_week,
    });

    calendar.setDate(newDate(datePickerVal));

    $datePicker.data('pikaday', calendar);
  });

  $('.js-clear-due-date,.js-clear-start-date').on('click', (e) => {
    e.preventDefault();
    const calendar = $(e.target)
      .siblings('.issuable-form-select-holder')
      .children('.datepicker')
      .data('pikaday');
    calendar.setDate(null);
  });
}
