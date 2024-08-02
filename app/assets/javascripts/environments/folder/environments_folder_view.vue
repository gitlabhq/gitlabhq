<script>
import { GlBadge, GlTab, GlTabs } from '@gitlab/ui';
import DeleteEnvironmentModal from '../components/delete_environment_modal.vue';
import StopEnvironmentModal from '../components/stop_environment_modal.vue';
import environmentsMixin from '../mixins/environments_mixin';
import EnvironmentsPaginationApiMixin from '../mixins/environments_pagination_api_mixin';
import ConfirmRollbackModal from '../components/confirm_rollback_modal.vue';

export default {
  components: {
    DeleteEnvironmentModal,
    GlBadge,
    GlTab,
    GlTabs,
    StopEnvironmentModal,
    ConfirmRollbackModal,
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
    <confirm-rollback-modal :environment="environmentInRollbackModal" />

    <h4 class="gl-font-normal" data-testid="folder-name">
      {{ s__('Environments|Environments') }} /
      <b>{{ folderName }}</b>
    </h4>

    <gl-tabs v-if="!isLoading" scope="environments" content-class="gl-hidden">
      <gl-tab
        v-for="(tab, i) in tabs"
        :key="`${tab.name}-${i}`"
        :active="tab.isActive"
        :title-item-class="tab.isActive ? 'gl-outline-none' : ''"
        :title-link-attributes="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
          'data-testid': `environments-tab-${tab.scope}`,
        } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
        @click="onChangeTab(tab.scope)"
      >
        <template #title>
          <span>{{ tab.name }}</span>
          <gl-badge class="gl-tab-counter-badge">{{ tab.count }}</gl-badge>
        </template>
      </gl-tab>
    </gl-tabs>

    <!-- eslint-disable-next-line vue/no-undef-components -->
    <container
      :is-loading="isLoading"
      :environments="state.environments"
      :pagination="state.paginationInformation"
      @onChangePage="onChangePage"
    />
  </div>
</template>
