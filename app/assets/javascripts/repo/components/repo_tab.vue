<script>
import Store from '../stores/repo_store';

const RepoTab = {
  props: {
    tab: {
      type: Object,
      required: true,
    },
  },

  computed: {
    closeLabel() {
      if (this.tab.changed) {
        return `${this.tab.name} changed`;
      }
      return `Close ${this.tab.name}`;
    },
    changedClass() {
      const tabChangedObj = {
        'fa-times close-icon': !this.tab.changed,
        'fa-circle unsaved-icon': this.tab.changed,
      };
      return tabChangedObj;
    },
  },

  methods: {
    tabClicked: Store.setActiveFiles,

    closeTab(file) {
      if (file.changed) return;
      this.$emit('tabclosed', file);
    },
  },
};

export default RepoTab;
</script>

<template>
<li @click="tabClicked(tab)">
  <a
    href="#0"
    class="close"
    @click.stop.prevent="closeTab(tab)"
    :aria-label="closeLabel">
    <i
      class="fa"
      :class="changedClass"
      aria-hidden="true">
    </i>
  </a>

  <a
    href="#"
    class="repo-tab"
    :title="tab.url"
    @click.prevent="tabClicked(tab)">
    {{tab.name}}
  </a>
</li>
</template>
