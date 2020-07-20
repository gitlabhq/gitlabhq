<script>
import TreeActionLink from './tree_action_link.vue';
import { __ } from '~/locale';
import { webIDEUrl } from '~/lib/utils/url_utility';

export default {
  components: {
    TreeActionLink,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    refSha: {
      type: String,
      required: true,
    },
    canPushCode: {
      type: Boolean,
      required: false,
      default: true,
    },
    forkPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    showLinkToFork() {
      return !this.canPushCode && this.forkPath;
    },
    text() {
      return this.showLinkToFork ? __('Edit fork in Web IDE') : __('Web IDE');
    },
    path() {
      const path = this.showLinkToFork ? this.forkPath : this.projectPath;
      return webIDEUrl(`/${path}/edit/${this.refSha}/-/${this.$route.params.path || ''}`);
    },
  },
};
</script>

<template>
  <tree-action-link :path="path" :text="text" data-qa-selector="web_ide_button" />
</template>
