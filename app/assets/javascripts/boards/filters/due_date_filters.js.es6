/* global Vue */
/* global dateFormat */

Vue.filter('due-date', (value) => {
  const date = new Date(value);
  return dateFormat(date, 'mmm d, yyyy');
});
