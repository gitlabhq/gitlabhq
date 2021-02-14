<script>
import { GlBadge, GlTab, GlTabs } from '@gitlab/ui';
import DeleteEnvironmentModal from '../components/delete_environment_modal.vue';
import StopEnvironmentModal from '../components/stop_environment_modal.vue';
import environmentsMixin from '../mixins/environments_mixin';
import EnvironmentsPaginationApiMixin from '../mixins/environments_pagination_api_mixin';

export default {
  components: {
    DeleteEnvironmentModal,
    GlBadge,
    GlTab,
    GlTabs,
    StopEnvironmentModal,
  },

  mixins: [environmentsMixin, EnvironmentsPaginationApiMixin],

  props: {
    endpoint: {
      type: String,
      required: true,
    },
    folderName: {
      type: String,
      required: true,
    },
    cssContainerClass: {
      type: String,
      required: false,
      default: '',
    },
    canReadEnvironment: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    successCallback(resp) {
      this.saveData(resp);
    },
  },
};
</script>
<template>
  <div :class="cssContainerClass">
    <stop-environment-modal :environment="environmentInStopModal" />
    <delete-environment-modal :environment="environmentInDeleteModal" />

    <h4 class="gl-font-weight-normal" data-testid="folder-name">
      {{ s__('Environments|Environments') }} /
      <b>{{ folderName }}</b>
    </h4>

    <gl-tabs v-if="!isLoading" scope="environments" content-class="gl-display-none">
      <gl-tab
        v-for="(tab, i) in tabs"
        :key="`${tab.name}-${i}`"
        :active="tab.isActive"
        :title-item-class="tab.isActive ? 'gl-outline-none' : ''"
        :title-link-attributes="{ 'data-testid': `environments-tab-${tab.scope}` }"
        @click="onChangeTab(tab.scope)"
      >
        <template #title>
          <span>{{ tab.name }}</span>
          <gl-badge size="sm" class="gl-tab-counter-badge">{{ tab.count }}</gl-badge>
        </template>
      </gl-tab>
    </gl-tabs>

    <container
      :is-loading="isLoading"
      :environments="state.environments"
      :pagination="state.paginationInformation"
      :can-read-environment="canReadEnvironment"
      @onChangePage="onChangePage"
    />
  </div>
</template>
