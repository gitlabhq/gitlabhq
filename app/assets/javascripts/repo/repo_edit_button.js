import Vue from 'vue';
import Store from './repo_store';
import RepoMixin from './repo_mixin'

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
          return this.editMode ? 'Cancel edit' : 'Edit';
        },

        buttonIcon() {
          return this.editMode ? [] : ['fa', 'fa-pencil'];
        },
      },
      methods: {
        editClicked() {
          if(this.changedFiles.length) {
            this.dialog.open = true;
            return;
          }
          this.editMode = !this.editMode;
        },
      },

      watch: {
        dialog: {
          handler(obj) {
            if(obj.status) {
              obj.status = false;
            }
          },
          deep: true,
        }
      }
    });
  }
}
