import Vue from 'vue';
import dateFormat from '~/lib/dateformat';

Vue.filter('due-date', (value) => {
  const date = new Date(value);
  return dateFormat(date, 'mmm d, yyyy', true);
});
