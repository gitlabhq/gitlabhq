import $ from 'jquery';
import GLForm from '~/gl_form';
import ZenMode from '~/zen_mode';

document.addEventListener('DOMContentLoaded', () => {
  new ZenMode(); // eslint-disable-line no-new
  new GLForm($('.release-form')); // eslint-disable-line no-new
});
