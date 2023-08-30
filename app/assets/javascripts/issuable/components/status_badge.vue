<script>
import { GlBadge, GlIcon } from '@gitlab/ui';
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
      icon: 'epic',
      text: __('Open'),
      variant: 'success',
    },
    [STATUS_CLOSED]: {
      icon: 'epic-closed',
      text: __('Closed'),
      variant: 'info',
    },
  },
  [TYPE_ISSUE]: {
    [STATUS_OPEN]: {
      icon: 'issues',
      text: __('Open'),
      variant: 'success',
    },
    [STATUS_CLOSED]: {
      icon: 'issue-closed',
      text: __('Closed'),
      variant: 'info',
    },
    [STATUS_LOCKED]: {
      icon: 'issues',
      text: __('Open'),
      variant: 'success',
    },
  },
  [TYPE_MERGE_REQUEST]: {
    [STATUS_OPEN]: {
      icon: 'merge-request-open',
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
      icon: 'merge-request-open',
      text: __('Open'),
      variant: 'success',
    },
  },
};

export default {
  components: {
    GlBadge,
    GlIcon,
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
  <gl-badge :variant="badgeProperties.variant" :aria-label="badgeProperties.text">
    <gl-icon :name="badgeProperties.icon" />
    <span class="gl-display-none gl-sm-display-block gl-ml-2">{{ badgeProperties.text }}</span>
  </gl-badge>
</template>
