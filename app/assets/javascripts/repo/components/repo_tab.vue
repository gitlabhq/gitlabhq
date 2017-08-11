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

    xClicked(file) {
      if (file.changed) return;
      this.$emit('xclicked', file);
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
    @click.stop.prevent="xClicked(tab)"
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
