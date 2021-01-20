import ZenMode from '~/zen_mode';
import GLForm from '~/gl_form';

export default function ($formEl) {
  new ZenMode(); // eslint-disable-line no-new
  new GLForm($formEl); // eslint-disable-line no-new
}
