import ZenMode from '~/zen_mode';
import GLForm from '~/gl_form';

export default function () {
  new ZenMode(); // eslint-disable-line no-new
  new GLForm($('.release-form'), true); // eslint-disable-line no-new
}
