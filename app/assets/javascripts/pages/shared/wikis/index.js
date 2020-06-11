import $ from 'jquery';
import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import csrf from '~/lib/utils/csrf';
import ShortcutsWiki from '~/behaviors/shortcuts/shortcuts_wiki';
import Wikis from './wikis';
import ZenMode from '../../../zen_mode';
import GLForm from '../../../gl_form';
import deleteWikiModal from './components/delete_wiki_modal.vue';

export default () => {
  new Wikis(); // eslint-disable-line no-new
  new ShortcutsWiki(); // eslint-disable-line no-new
  new ZenMode(); // eslint-disable-line no-new
  new GLForm($('.wiki-form')); // eslint-disable-line no-new

  const deleteWikiModalWrapperEl = document.getElementById('delete-wiki-modal-wrapper');

  if (deleteWikiModalWrapperEl) {
    Vue.use(Translate);

    const { deleteWikiUrl, pageTitle } = deleteWikiModalWrapperEl.dataset;

    // eslint-disable-next-line no-new
    new Vue({
      el: deleteWikiModalWrapperEl,
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
};
