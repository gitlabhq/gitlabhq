import Vue from 'vue';
import Store from './stores/repo_store';
import RepoMixin from './mixins/repo_mixin';
import { __ } from '../locale';

export default class RepoEditButton {
  constructor(el) {
    this.initVue(el);
  }

  initVue(el) {
    this.vue = new Vue({
      el,
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
    });
  }
}
