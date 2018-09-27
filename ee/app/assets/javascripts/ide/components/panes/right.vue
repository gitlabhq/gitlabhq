<script>
import RightPane from '~/ide/components/panes/right.vue';

export default {
  name: 'EERightPane',
  components: {
    RightPane,
  },
  computed: {
    extensionTabs() {
      // This is empty for now, but it will be used in: https://gitlab.com/gitlab-org/gitlab-ee/issues/5426
      return [];
    },
  },
};
</script>

<template>
  <right-pane :extension-tabs="extensionTabs"/>
</template>
