import Vue from 'vue';
import Store from '../stores/repo_store';
import RepoMixin from '../mixins/repo_mixin';
import Translate from '../../vue_shared/translate';
import { __ } from '../../locale';

Vue.use(Translate);

const RepoEditButton = {
  el: undefined,
  mixins: [RepoMixin],
  data: () => Store,
  computed: {
    buttonLabel() {
      return this.editMode ? __('Cancel edit') : __('Edit');
    },

    buttonIcon() {
      return this.editMode ? [] : ['fa', 'fa-pencil'];
    },
  },
  methods: {
    editClicked() {
      if (this.changedFiles.length) {
        this.dialog.open = true;
        return;
      }
      this.editMode = !this.editMode;
    },
  },
};

function initRepoEditButtonViewModel(el) {
  RepoEditButton.el = el;

  return new Vue(RepoEditButton);
}

export {
  RepoEditButton as default,
  initRepoEditButtonViewModel,
};
