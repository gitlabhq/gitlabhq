import dateFormat, { i18n, masks } from 'dateformat';
import { s__, __ } from '~/locale';

i18n.dayNames = [
  __('Sun'),
  __('Mon'),
  __('Tue'),
  __('Wed'),
  __('Thu'),
  __('Fri'),
  __('Sat'),
  __('Sunday'),
  __('Monday'),
  __('Tuesday'),
  __('Wednesday'),
  __('Thursday'),
  __('Friday'),
  __('Saturday'),
];

i18n.monthNames = [
  __('Jan'),
  __('Feb'),
  __('Mar'),
  __('Apr'),
  __('May'),
  __('Jun'),
  __('Jul'),
  __('Aug'),
  __('Sep'),
  __('Oct'),
  __('Nov'),
  __('Dec'),
  __('January'),
  __('February'),
  __('March'),
  __('April'),
  __('May'),
  __('June'),
  __('July'),
  __('August'),
  __('September'),
  __('October'),
  __('November'),
  __('December'),
];

i18n.timeNames = [
  s__('Time|a'),
  s__('Time|p'),
  s__('Time|am'),
  s__('Time|pm'),
  s__('Time|A'),
  s__('Time|P'),
  s__('Time|AM'),
  s__('Time|PM'),
];

export { masks };
export default dateFormat;
