import $ from 'jquery';
import GLForm from '~/gl_form';
import ZenMode from '~/zen_mode';
import initNewTagRefSelector from '~/tags/init_new_tag_ref_selector';

initNewTagRefSelector();
new ZenMode(); // eslint-disable-line no-new
new GLForm($('.tag-form')); // eslint-disable-line no-new
