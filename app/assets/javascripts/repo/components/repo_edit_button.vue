<script>
import Store from '../stores/repo_store';
import RepoMixin from '../mixins/repo_mixin';

export default {
  data: () => Store,
  mixins: [RepoMixin],
  computed: {
    buttonLabel() {
      return this.editMode ? this.__('Cancel edit') : this.__('Edit');
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
}
</script>

<template>
<a href="#" @click.prevent="editClicked" v-cloak v-if="isCommitable">
  <i :class="buttonIcon"></i>
  <span>{{buttonLabel}}</span>
</a>
</template>
