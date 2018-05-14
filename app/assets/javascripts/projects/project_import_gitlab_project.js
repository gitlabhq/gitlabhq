import $ from 'jquery';
import { getParameterValues } from '../lib/utils/url_utility';

export default () => {
  const path = getParameterValues('path')[0];

  // get the path url and append it in the inputS
  $('.js-path-name').val(path);
};
