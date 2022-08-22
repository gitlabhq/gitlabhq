/**
 * Function that replaces the open attribute for the <details> element.
 *
 * @param {String} descriptionHtml - The html string passed back from the server as a result of polling
 * @param {Array} details - All detail nodes inside of the issue description.
 */

const updateDescription = (descriptionHtml = '', details) => {
  let detailNodes = details;

  if (!details.length) {
    detailNodes = [];
  }

  const placeholder = document.createElement('div');
  // eslint-disable-next-line no-unsanitized/property
  placeholder.innerHTML = descriptionHtml;

  const newDetails = placeholder.getElementsByTagName('details');

  if (newDetails.length !== detailNodes.length) {
    return descriptionHtml;
  }

  Array.from(newDetails).forEach((el, i) => {
    /*
     * <details> has an open attribute that can have a value, "", "true", "false"
     * and will show the dropdown, which is why we are setting the attribute
     * explicitly to true.
     */
    if (detailNodes[i].open) el.setAttribute('open', true);
  });

  return placeholder.innerHTML;
};

export default updateDescription;
