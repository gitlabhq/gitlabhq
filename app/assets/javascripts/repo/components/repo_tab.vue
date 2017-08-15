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
        'fa-times': !this.tab.changed,
        'fa-circle': this.tab.changed,
      };
      return tabChangedObj;
    },
  },

  methods: {
    tabClicked: Store.setActiveFiles,

    xClicked(file) {
      if (file.changed) return;
      this.$emit('xclicked', file);
    },
  },
};

export default RepoTab;
</script>

<template>
<li>
  <a
    href="#0"
    class="close"
    @click.prevent="xClicked(tab)"
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
