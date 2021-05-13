import $ from 'jquery';
import Pikaday from 'pikaday';
import { parsePikadayDate, pikadayToString } from '~/lib/utils/datetime_utility';

export default function initDatePickers() {
  $('.datepicker').each(function initPikaday() {
    const $datePicker = $(this);
    const datePickerVal = $datePicker.val();

    const calendar = new Pikaday({
      field: $datePicker.get(0),
      theme: 'gitlab-theme animate-picker',
      format: 'yyyy-mm-dd',
      container: $datePicker.parent().get(0),
      parse: (dateString) => parsePikadayDate(dateString),
      toString: (date) => pikadayToString(date),
      onSelect(dateText) {
        $datePicker.val(calendar.toString(dateText));
      },
      firstDay: gon.first_day_of_week,
    });

    calendar.setDate(parsePikadayDate(datePickerVal));

    $datePicker.data('pikaday', calendar);
  });

  $('.js-clear-due-date,.js-clear-start-date').on('click', (e) => {
    e.preventDefault();
    const calendar = $(e.target).siblings('.datepicker').data('pikaday');
    calendar.setDate(null);
  });
}
