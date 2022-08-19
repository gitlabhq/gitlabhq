import $ from 'jquery';
import GLForm from '~/gl_form';
import initFilePickers from '~/file_pickers';
import ZenMode from '~/zen_mode';
import { initRemoveAvatar } from '~/admin/topics';

new GLForm($('.js-project-topic-form')); // eslint-disable-line no-new
initFilePickers();
new ZenMode(); // eslint-disable-line no-new

initRemoveAvatar();
