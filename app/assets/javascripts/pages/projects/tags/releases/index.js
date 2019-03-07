import $ from 'jquery';
import ZenMode from '~/zen_mode';
import GLForm from '~/gl_form';

document.addEventListener('DOMContentLoaded', () => {
  new ZenMode(); // eslint-disable-line no-new
  new GLForm($('.release-form')); // eslint-disable-line no-new
});
