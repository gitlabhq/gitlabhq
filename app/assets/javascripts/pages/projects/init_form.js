import GLForm from '~/gl_form';
import ZenMode from '~/zen_mode';

export default function initProjectForm($formEl) {
  new ZenMode(); // eslint-disable-line no-new
  new GLForm($formEl); // eslint-disable-line no-new
}
