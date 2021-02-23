import $ from 'jquery';
import GLForm from '../../../../gl_form';
import RefSelectDropdown from '../../../../ref_select_dropdown';
import ZenMode from '../../../../zen_mode';

new ZenMode(); // eslint-disable-line no-new
new GLForm($('.tag-form')); // eslint-disable-line no-new
new RefSelectDropdown($('.js-branch-select')); // eslint-disable-line no-new
