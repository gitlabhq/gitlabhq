import $ from 'jquery';
import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import csrf from '~/lib/utils/csrf';
import Wikis from './wikis';
import ShortcutsWiki from '../../../shortcuts_wiki';
import ZenMode from '../../../zen_mode';
import GLForm from '../../../gl_form';
import deleteWikiModal from './components/delete_wiki_modal.vue';

document.addEventListener('DOMContentLoaded', () => {
  new Wikis(); // eslint-disable-line no-new
  new ShortcutsWiki(); // eslint-disable-line no-new
  new ZenMode(); // eslint-disable-line no-new
  new GLForm($('.wiki-form')); // eslint-disable-line no-new

  const deleteWikiButton = document.getElementById('delete-wiki-button');

  if (deleteWikiButton) {
    Vue.use(Translate);

    const { deleteWikiUrl, pageTitle } = deleteWikiButton.dataset;
    const deleteWikiModalEl = document.getElementById('delete-wiki-modal');
    const deleteModal = new Vue({ // eslint-disable-line
      el: deleteWikiModalEl,
      data: {
        deleteWikiUrl: '',
      },
      render(createElement) {
        return createElement(deleteWikiModal, {
          props: {
            pageTitle,
            deleteWikiUrl,
            csrfToken: csrf.token,
          },
        });
      },
    });
  }
});
