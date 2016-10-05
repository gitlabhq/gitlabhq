Vue.filter('due-date', (value) => {
  const date = new Date(value.replace(new RegExp('-', 'g'), ','));
  return $.datepicker.formatDate('M d, yy', date);
});
