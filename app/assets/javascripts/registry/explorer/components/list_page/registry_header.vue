<script>
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import { n__, sprintf } from '~/locale';
import { approximateDuration, calculateRemainingMilliseconds } from '~/lib/utils/datetime_utility';

import {
  CONTAINER_REGISTRY_TITLE,
  LIST_INTRO_TEXT,
  EXPIRATION_POLICY_WILL_RUN_IN,
  EXPIRATION_POLICY_DISABLED_TEXT,
  EXPIRATION_POLICY_DISABLED_MESSAGE,
} from '../../constants/index';

export default {
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
    expirationPolicyHelpPagePath: {
      type: String,
      default: '',
      required: false,
    },
    hideExpirationPolicyData: {
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
    showExpirationPolicyTip() {
      return (
        !this.expirationPolicyEnabled && this.imagesCount > 0 && !this.hideExpirationPolicyData
      );
    },
    infoMessages() {
      const base = [{ text: LIST_INTRO_TEXT, link: this.helpPagePath }];
      return this.showExpirationPolicyTip
        ? [
            ...base,
            { text: EXPIRATION_POLICY_DISABLED_MESSAGE, link: this.expirationPolicyHelpPagePath },
          ]
        : base;
    },
  },
};
</script>

<template>
  <title-area :title="$options.i18n.CONTAINER_REGISTRY_TITLE" :info-messages="infoMessages">
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
