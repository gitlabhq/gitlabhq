import $ from 'jquery';
import Wikis from './wikis';
import ShortcutsWiki from '../../../shortcuts_wiki';
import ZenMode from '../../../zen_mode';
import GLForm from '../../../gl_form';

document.addEventListener('DOMContentLoaded', () => {
  new Wikis(); // eslint-disable-line no-new
  new ShortcutsWiki(); // eslint-disable-line no-new
  new ZenMode(); // eslint-disable-line no-new
  new GLForm($('.wiki-form'), true); // eslint-disable-line no-new
});
