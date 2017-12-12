import { getParameterValues } from '../lib/utils/url_utility';

const bindEvents = () => {
  const path = getParameterValues('path')[0];

  // get the path url and append it in the inputS
  $('.js-path-name').val(path);
};

document.addEventListener('DOMContentLoaded', bindEvents);

export default {
  bindEvents,
};
