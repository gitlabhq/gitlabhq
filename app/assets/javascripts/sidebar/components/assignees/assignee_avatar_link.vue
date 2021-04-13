<script>
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { isUserBusy } from '~/set_status_modal/utils';
import AssigneeAvatar from './assignee_avatar.vue';

const I18N = {
  BUSY: __('Busy'),
  CANNOT_MERGE: __('Cannot merge'),
  LC_CANNOT_MERGE: __('cannot merge'),
};

const paranthesize = (str) => `(${str})`;

const generateAssigneeTooltip = ({
  name,
  availability,
  cannotMerge = true,
  tooltipHasName = false,
}) => {
  if (!tooltipHasName) {
    return cannotMerge ? I18N.CANNOT_MERGE : '';
  }

  const statusInformation = [];
  if (availability && isUserBusy(availability)) {
    statusInformation.push(I18N.BUSY);
  }

  if (cannotMerge) {
    statusInformation.push(I18N.LC_CANNOT_MERGE);
  }

  if (tooltipHasName && statusInformation.length) {
    return sprintf(__('%{name} %{status}'), {
      name,
      status: statusInformation.map(paranthesize).join(' '),
    });
  }

  return name;
};

export default {
  components: {
    AssigneeAvatar,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
    tooltipPlacement: {
      type: String,
      default: 'bottom',
      required: false,
    },
    tooltipHasName: {
      type: Boolean,
      default: true,
      required: false,
    },
    issuableType: {
      type: String,
      default: 'issue',
      required: false,
    },
  },
  computed: {
    cannotMerge() {
      return this.issuableType === 'merge_request' && !this.user.can_merge;
    },
    tooltipTitle() {
      const { name = '', availability = '' } = this.user;
      return generateAssigneeTooltip({
        name,
        availability,
        cannotMerge: this.cannotMerge,
        tooltipHasName: this.tooltipHasName,
      });
    },
    tooltipOption() {
      return {
        container: 'body',
        placement: this.tooltipPlacement,
        boundary: 'viewport',
      };
    },
    assigneeUrl() {
      return this.user.web_url || this.user.webUrl;
    },
  },
};
</script>

<template>
  <!-- must be `d-inline-block` or parent flex-basis causes width issues -->
  <gl-link
    v-gl-tooltip="tooltipOption"
    :href="assigneeUrl"
    :title="tooltipTitle"
    class="gl-display-inline-block"
  >
    <!-- use d-flex so that slot can be appropriately styled -->
    <span class="gl-display-flex">
      <assignee-avatar :user="user" :img-size="32" :issuable-type="issuableType" />
      <slot></slot>
    </span>
  </gl-link>
</template>
