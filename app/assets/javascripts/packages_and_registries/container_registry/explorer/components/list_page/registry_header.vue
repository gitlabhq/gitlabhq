<script>
import { GlLink } from '@gitlab/ui';
import { approximateDuration, calculateRemainingMilliseconds } from '~/lib/utils/datetime_utility';
import { n__, sprintf } from '~/locale';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

import {
  CONTAINER_REGISTRY_TITLE,
  EXPIRATION_POLICY_WILL_RUN_IN,
  EXPIRATION_POLICY_DISABLED_TEXT,
  SET_UP_CLEANUP,
} from '../../constants/index';

export default {
  name: 'ListHeader',
  components: {
    TitleArea,
    MetadataItem,
    GlLink,
    MetadataContainerScanning: () =>
      import(
        'ee_component/packages_and_registries/container_registry/explorer/components/list_page/metadata_container_scanning.vue'
      ),
    ContainerScanningCounts: () =>
      import(
        'ee_component/packages_and_registries/container_registry/explorer/components/list_page/container_scanning_counts.vue'
      ),
  },
  inject: ['config'],
  props: {
    expirationPolicy: {
      type: Object,
      default: () => ({}),
      required: false,
    },
    imagesCount: {
      type: Number,
      default: 0,
      required: false,
    },
    helpPagePath: {
      type: String,
      default: '',
      required: false,
    },
    hideExpirationPolicyData: {
      type: Boolean,
      required: false,
      default: false,
    },
    metadataLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    cleanupPoliciesSettingsPath: {
      type: String,
      default: '',
      required: false,
    },
    showCleanupPolicyLink: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  loader: {
    repeat: 10,
    width: 1000,
    height: 40,
  },
  i18n: {
    CONTAINER_REGISTRY_TITLE,
    SET_UP_CLEANUP,
  },
  computed: {
    imagesCountText() {
      const pluralisedString = n__(
        'ContainerRegistry|%{count} Image repository',
        'ContainerRegistry|%{count} Image repositories',
        this.imagesCount,
      );
      return sprintf(pluralisedString, { count: this.imagesCount });
    },
    timeTillRun() {
      const difference = calculateRemainingMilliseconds(this.expirationPolicy?.next_run_at);
      return approximateDuration(difference / 1000);
    },
    expirationPolicyEnabled() {
      return this.expirationPolicy?.enabled;
    },
    expirationPolicyText() {
      return this.expirationPolicyEnabled
        ? sprintf(EXPIRATION_POLICY_WILL_RUN_IN, { time: this.timeTillRun })
        : EXPIRATION_POLICY_DISABLED_TEXT;
    },
  },
};
</script>

<template>
  <title-area :title="$options.i18n.CONTAINER_REGISTRY_TITLE" :metadata-loading="metadataLoading">
    <template #right-actions>
      <slot name="commands"></slot>
    </template>
    <template v-if="imagesCount" #metadata-count>
      <metadata-item
        data-testid="images-count"
        icon="container-image"
        :text="imagesCountText"
        size="xl"
      />
    </template>
    <template #metadata-exp-policies>
      <metadata-item
        v-if="!hideExpirationPolicyData"
        data-testid="expiration-policy"
        icon="clock"
        :text="expirationPolicyText"
        size="xl"
      />
      <gl-link v-if="showCleanupPolicyLink" class="gl-ml-2" :href="cleanupPoliciesSettingsPath">{{
        $options.i18n.SET_UP_CLEANUP
      }}</gl-link>
    </template>
    <template v-if="!config.isGroupPage" #metadata-container-scanning>
      <metadata-container-scanning />
    </template>

    <template v-if="!config.isGroupPage">
      <container-scanning-counts />
    </template>
  </title-area>
</template>
