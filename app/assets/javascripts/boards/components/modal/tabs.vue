<script>
/* eslint-disable @gitlab/vue-require-i18n-strings */
import { GlTabs, GlTab, GlBadge } from '@gitlab/ui';
import ModalStore from '../../stores/modal_store';
import modalMixin from '../../mixins/modal_mixins';

export default {
  components: {
    GlTabs,
    GlTab,
    GlBadge,
  },
  mixins: [modalMixin],
  data() {
    return ModalStore.store;
  },
  computed: {
    selectedCount() {
      return ModalStore.selectedCount();
    },
  },
  destroyed() {
    this.activeTab = 'all';
  },
};
</script>
<template>
  <gl-tabs class="gl-mt-3">
    <gl-tab @click.prevent="changeTab('all')">
      <template slot="title">
        <span>Open issues</span>
        <gl-badge size="sm" class="gl-tab-counter-badge">{{ issuesCount }}</gl-badge>
      </template>
    </gl-tab>
    <gl-tab @click.prevent="changeTab('selected')">
      <template slot="title">
        <span>Selected issues</span>
        <gl-badge size="sm" class="gl-tab-counter-badge">{{ selectedCount }}</gl-badge>
      </template>
    </gl-tab>
  </gl-tabs>
</template>
