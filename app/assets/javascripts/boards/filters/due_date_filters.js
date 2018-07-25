import Vue from 'vue';
import dateFormat from 'dateformat';

Vue.filter('due-date', value => {
  const date = new Date(value);
  return dateFormat(date, 'mmm d, yyyy', true);
});
