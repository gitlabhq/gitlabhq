<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';
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
  },
  computed: {
    badgeProperties() {
      if (this.issuableType === TYPE_MERGE_REQUEST) {
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
