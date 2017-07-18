import Vue from 'vue';
import Store from './repo_store';

export default class RepoEditButton {
  constructor(el) {
    this.initVue(el);
  }

  initVue(el) {
    this.vue = new Vue({
      el,
      data: () => Store,
      computed: {
        buttonLabel() {
          return this.editMode ? 'Read-only mode' : 'Edit mode';
        },

        buttonIcon() {
          return this.editMode ? [] : ['fa', 'fa-pencil'];
        },
      },
      methods: {
        editClicked() {
          this.editMode = !this.editMode;
        },
      },
    });
  }
}
