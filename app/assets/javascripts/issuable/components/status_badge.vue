<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  STATUS_CLOSED,
  STATUS_LOCKED,
  STATUS_MERGED,
  STATUS_OPEN,
  TYPE_MERGE_REQUEST,
} from '~/issues/constants';
import { STATE_CLOSED } from '~/work_items/constants';

const mergeRequestPropertiesMap = {
  [STATUS_OPEN]: {
    icon: 'merge-request',
    text: __('Open'),
    variant: 'success',
  },
  [STATUS_CLOSED]: {
    icon: 'merge-request-close',
    text: __('Closed'),
    variant: 'danger',
  },
  [STATUS_MERGED]: {
    icon: 'merge',
    text: __('Merged'),
    variant: 'info',
  },
  [STATUS_LOCKED]: {
    icon: 'merge-request',
    text: __('Open'),
    variant: 'success',
  },
};

export default {
  components: {
    GlBadge,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    issuableType: {
      type: String,
      required: false,
      default: '',
    },
    state: {
      type: String,
      required: false,
      default: null,
    },
    isDraft: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    badgeProperties() {
      if (this.issuableType === TYPE_MERGE_REQUEST) {
        if (
          this.state === STATUS_OPEN &&
          this.isDraft === true &&
          this.glFeatures.showMergeRequestStatusDraft
        ) {
          return {
            icon: 'merge-request',
            text: __('Draft'),
            variant: 'warning',
          };
        }
        return mergeRequestPropertiesMap[this.state];
      }

      if (this.state === STATUS_CLOSED || this.state === STATE_CLOSED) {
        return {
          icon: 'issue-close',
          text: __('Closed'),
          variant: 'info',
        };
      }

      return {
        icon: 'issue-open-m',
        text: __('Open'),
        variant: 'success',
      };
    },
  },
};
</script>

<template>
  <gl-badge
    :variant="badgeProperties.variant"
    :icon="badgeProperties.icon"
    :aria-label="badgeProperties.text"
    class="gl-shrink-0"
  >
    {{ badgeProperties.text }}
  </gl-badge>
</template>
