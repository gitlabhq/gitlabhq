import $ from 'jquery';
import ShortcutsWiki from '~/behaviors/shortcuts/shortcuts_wiki';
import GLForm from '~/gl_form';

import Wikis from './wikis';

document.addEventListener('DOMContentLoaded', () => {
  new Wikis(); // eslint-disable-line no-new
  new ShortcutsWiki(); // eslint-disable-line no-new
  new GLForm($('.wiki-form')); // eslint-disable-line no-new
});
