<script>
import RepoStore from './repo_store';

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
        'fa-times': !this.tab.changed,
        'fa-circle': this.tab.changed,
      };
      return tabChangedObj;
    },
  },

  methods: {
    tabClicked: RepoStore.setActiveFiles.bind(RepoStore),

    xClicked(file) {
      if (file.changed) return;
      RepoStore.removeFromOpenedFiles(file);
    },
  },
};

export default RepoTab;
</script>

<template>
<li>
  <a href="#" @click.prevent="xClicked(tab)" v-if="!tab.loading">
    <i class="fa" :class="changedClass"></i>
  </a>

  <a href="#" v-if="!tab.loading" :title="tab.url" @click.prevent="tabClicked(tab)">{{tab.name}}</a>

  <i v-if="tab.loading" class="fa fa-spinner fa-spin"></i>
</li>
</template>
