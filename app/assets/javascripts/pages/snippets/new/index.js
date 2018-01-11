import GLForm from '~/gl_form';
import ZenMode from '~/zen_mode';

export default function () {
  new GLForm($('.snippet-form'), false); // eslint-disable-line no-new
  new ZenMode(); // eslint-disable-line no-new
}
