<script>
import { GlSprintf, GlLink, GlIcon } from '@gitlab/ui';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { n__ } from '~/locale';
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
    GlIcon,
    GlSprintf,
    GlLink,
    TitleArea,
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
    LIST_INTRO_TEXT,
    EXPIRATION_POLICY_DISABLED_MESSAGE,
  },
  computed: {
    imagesCountText() {
      return n__(
        'ContainerRegistry|%{count} Image repository',
        'ContainerRegistry|%{count} Image repositories',
        this.imagesCount,
      );
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
        ? EXPIRATION_POLICY_WILL_RUN_IN
        : EXPIRATION_POLICY_DISABLED_TEXT;
    },
    showExpirationPolicyTip() {
      return (
        !this.expirationPolicyEnabled && this.imagesCount > 0 && !this.hideExpirationPolicyData
      );
    },
  },
};
</script>

<template>
  <div>
    <title-area :title="$options.i18n.CONTAINER_REGISTRY_TITLE">
      <template #right-actions>
        <slot name="commands"></slot>
      </template>
      <template #metadata_count>
        <span v-if="imagesCount" data-testid="images-count">
          <gl-icon class="gl-mr-1" name="container-image" />
          <gl-sprintf :message="imagesCountText">
            <template #count>
              {{ imagesCount }}
            </template>
          </gl-sprintf>
        </span>
      </template>
      <template #metadata_exp_policies>
        <span v-if="!hideExpirationPolicyData" data-testid="expiration-policy">
          <gl-icon class="gl-mr-1" name="expire" />
          <gl-sprintf :message="expirationPolicyText">
            <template #time>
              {{ timeTillRun }}
            </template>
          </gl-sprintf>
        </span>
      </template>
    </title-area>

    <div data-testid="info-area">
      <p>
        <span data-testid="default-intro">
          <gl-sprintf :message="$options.i18n.LIST_INTRO_TEXT">
            <template #docLink="{content}">
              <gl-link :href="helpPagePath" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </span>
        <span v-if="showExpirationPolicyTip" data-testid="expiration-disabled-message">
          <gl-sprintf :message="$options.i18n.EXPIRATION_POLICY_DISABLED_MESSAGE">
            <template #docLink="{content}">
              <gl-link :href="expirationPolicyHelpPagePath" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </span>
      </p>
    </div>
  </div>
</template>
