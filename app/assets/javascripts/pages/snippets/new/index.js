/* eslint-disable no-new */
import GLForm from '~/gl_form';
import ZenMode from '~/zen_mode';

export default () => {
  new GLForm($('.snippet-form'), false);
  new ZenMode();
};
