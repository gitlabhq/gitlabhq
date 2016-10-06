Vue.filter('due-date', (value) => {
  const date = new Date(value);
  return $.datepicker.formatDate('M d, yy', date);
});
