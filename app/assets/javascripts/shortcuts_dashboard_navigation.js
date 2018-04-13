/**
 * Helper function that finds the href of the fiven selector and updates the location.
 *
 * @param  {String} selector
 */
export default selector => {
  const element = document.querySelector(selector);
  const link = element && element.getAttribute('href');

  if (link) {
    window.location = link;
  }
};
