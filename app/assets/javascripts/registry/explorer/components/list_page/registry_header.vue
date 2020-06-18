<script>
import { GlSprintf, GlLink, GlIcon } from '@gitlab/ui';
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
    <div
      class="gl-display-flex gl-justify-content-space-between gl-align-items-center"
      data-testid="header"
    >
      <h4 data-testid="title">{{ $options.i18n.CONTAINER_REGISTRY_TITLE }}</h4>
      <div class="gl-display-none d-sm-block" data-testid="commands-slot">
        <slot name="commands"></slot>
      </div>
    </div>
    <div
      v-if="imagesCount"
      class="gl-display-flex gl-align-items-center gl-mt-1 gl-mb-3 gl-text-gray-700"
      data-testid="subheader"
    >
      <span class="gl-mr-3" data-testid="images-count">
        <gl-icon class="gl-mr-1" name="container-image" />
        <gl-sprintf :message="imagesCountText">
          <template #count>
            {{ imagesCount }}
          </template>
        </gl-sprintf>
      </span>
      <span v-if="!hideExpirationPolicyData" data-testid="expiration-policy">
        <gl-icon class="gl-mr-1" name="expire" />
        <gl-sprintf :message="expirationPolicyText">
          <template #time>
            {{ timeTillRun }}
          </template>
        </gl-sprintf>
      </span>
    </div>
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
