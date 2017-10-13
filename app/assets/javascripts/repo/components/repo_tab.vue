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
    tabClicked(file) {
      Store.setActiveFiles(file);
    },
    closeTab(file) {
      if (file.changed) return;

      Store.removeFromOpenedFiles(file);
    },
  },
};

export default RepoTab;
</script>

<template>
  <li
    :class="{ active : tab.active }"
    @click="tabClicked(tab)"
  >
    <button
      type="button"
      class="close-btn"
      @click.stop.prevent="closeTab(tab)"
      :aria-label="closeLabel">
      <i
        class="fa"
        :class="changedClass"
        aria-hidden="true">
      </i>
    </button>

    <a
      href="#"
      class="repo-tab"
      :title="tab.url"
      @click.prevent="tabClicked(tab)">
      {{tab.name}}
    </a>
  </li>
</template>
