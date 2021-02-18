import dateFormat from 'dateformat';
import Vue from 'vue';

Vue.filter('due-date', (value) => {
  const date = new Date(value);
  return dateFormat(date, 'mmm d, yyyy', true);
});
