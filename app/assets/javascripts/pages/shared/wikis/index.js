import $ from 'jquery';
import Vue from 'vue';
import ShortcutsWiki from '~/behaviors/shortcuts/shortcuts_wiki';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import csrf from '~/lib/utils/csrf';
import Translate from '~/vue_shared/translate';
import GLForm from '../../../gl_form';
import ZenMode from '../../../zen_mode';
import deleteWikiModal from './components/delete_wiki_modal.vue';
import wikiAlert from './components/wiki_alert.vue';
import wikiForm from './components/wiki_form.vue';
import Wikis from './wikis';

const createModalVueApp = () => {
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
      data() {
        return {
          deleteWikiUrl: '',
        };
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

const createAlertVueApp = () => {
  const el = document.getElementById('js-wiki-error');
  if (el) {
    const { error, wikiPagePath } = el.dataset;

    // eslint-disable-next-line no-new
    new Vue({
      el,
      render(createElement) {
        return createElement(wikiAlert, {
          props: {
            error,
            wikiPagePath,
          },
        });
      },
    });
  }
};

const createWikiFormApp = () => {
  const el = document.getElementById('js-wiki-form');

  if (el) {
    const { pageInfo, formatOptions } = el.dataset;

    // eslint-disable-next-line no-new
    new Vue({
      el,
      provide: {
        formatOptions: JSON.parse(formatOptions),
        pageInfo: convertObjectPropsToCamelCase(JSON.parse(pageInfo)),
      },
      render(createElement) {
        return createElement(wikiForm);
      },
    });
  }
};

export default () => {
  createModalVueApp();
  createAlertVueApp();
  createWikiFormApp();
};
