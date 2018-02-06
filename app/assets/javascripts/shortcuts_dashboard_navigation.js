/**
 * Helper function that finds the href of the fiven selector and updates the location.
 *
 * @param  {String} selector
 */
export default (selector) => {
  const link = document.querySelector(selector).getAttribute('href');

  if (link) {
    window.location = link;
  }
};
