<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';
import {
  STATUS_CLOSED,
  STATUS_LOCKED,
  STATUS_MERGED,
  STATUS_OPEN,
  TYPE_EPIC,
  TYPE_ISSUE,
  TYPE_MERGE_REQUEST,
} from '~/issues/constants';

const badgePropertiesMap = {
  [TYPE_EPIC]: {
    [STATUS_OPEN]: {
      icon: 'issue-open-m',
      text: __('Open'),
      variant: 'success',
    },
    [STATUS_CLOSED]: {
      icon: 'issue-close',
      text: __('Closed'),
      variant: 'info',
    },
  },
  [TYPE_ISSUE]: {
    [STATUS_OPEN]: {
      icon: 'issue-open-m',
      text: __('Open'),
      variant: 'success',
    },
    [STATUS_CLOSED]: {
      icon: 'issue-close',
      text: __('Closed'),
      variant: 'info',
    },
    [STATUS_LOCKED]: {
      icon: 'issue-open-m',
      text: __('Open'),
      variant: 'success',
    },
  },
  [TYPE_MERGE_REQUEST]: {
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
      return badgePropertiesMap[this.issuableType][this.state];
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
