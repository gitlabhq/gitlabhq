<script>
import { approximateDuration, calculateRemainingMilliseconds } from '~/lib/utils/datetime_utility';
import { n__, sprintf } from '~/locale';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

import {
  CONTAINER_REGISTRY_TITLE,
  LIST_INTRO_TEXT,
  EXPIRATION_POLICY_WILL_RUN_IN,
  EXPIRATION_POLICY_DISABLED_TEXT,
} from '../../constants/index';

export default {
  name: 'ListHeader',
  components: {
    TitleArea,
    MetadataItem,
  },
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
  },
  loader: {
    repeat: 10,
    width: 1000,
    height: 40,
  },
  i18n: {
    CONTAINER_REGISTRY_TITLE,
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
    infoMessages() {
      return [{ text: LIST_INTRO_TEXT, link: this.helpPagePath }];
    },
  },
};
</script>

<template>
  <title-area
    :title="$options.i18n.CONTAINER_REGISTRY_TITLE"
    :info-messages="infoMessages"
    :metadata-loading="metadataLoading"
  >
    <template #right-actions>
      <slot name="commands"></slot>
    </template>
    <template #metadata-count>
      <metadata-item
        v-if="imagesCount"
        data-testid="images-count"
        icon="container-image"
        :text="imagesCountText"
      />
    </template>
    <template #metadata-exp-policies>
      <metadata-item
        v-if="!hideExpirationPolicyData"
        data-testid="expiration-policy"
        icon="expire"
        :text="expirationPolicyText"
        size="xl"
      />
    </template>
  </title-area>
</template>
