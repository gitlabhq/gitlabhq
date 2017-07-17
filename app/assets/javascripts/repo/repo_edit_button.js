import Service from './repo_service'
import Helper from './repo_helper'
import Vue from 'vue'
import Store from './repo_store'

export default class RepoEditButton {
  constructor() {
    this.initVue();
    this.el = document.getElementById('editable-mode');
  }

  initVue() {
    this.vue = new Vue({
      el: '#editable-mode',
      data: () => Store,
      computed: {
        buttonLabel() {
          return this.editMode ? 'Read-only mode' : 'Edit mode';
        },

        buttonIcon() {
          return this.editMode ? [] : ['fa', 'fa-pencil']; 
        }
      },
      methods: {
        editClicked() {
          this.editMode = !this.editMode;
        }
      }
    });
  }
}