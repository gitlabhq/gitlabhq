import $ from 'jquery';
import GLForm from '~/gl_form';
import ZenMode from '~/zen_mode';

export default () => {
  new GLForm($('.snippet-form'), false); // eslint-disable-line no-new
  new ZenMode(); // eslint-disable-line no-new
};
