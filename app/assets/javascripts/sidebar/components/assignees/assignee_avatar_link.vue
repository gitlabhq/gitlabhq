<script>
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import { isGid, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
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
    const status = statusInformation.map(paranthesize).join(' ');

    return `${name} ${status}`;
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
      default: TYPE_ISSUE,
      required: false,
    },
  },
  computed: {
    isMergeRequest() {
      return this.issuableType === TYPE_MERGE_REQUEST;
    },
    cannotMerge() {
      const canMerge = this.user.mergeRequestInteraction?.canMerge || this.user.can_merge;
      return this.isMergeRequest && !canMerge;
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
      if (this.isMergeRequest) {
        return null;
      }

      return {
        container: 'body',
        placement: this.tooltipPlacement,
        boundary: 'viewport',
      };
    },
    assigneeUrl() {
      return this.user.web_url || this.user.webUrl;
    },
    assigneeId() {
      if (this.isMergeRequest) {
        return null;
      }

      return isGid(this.user.id) ? getIdFromGraphQLId(this.user.id) : this.user.id;
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
    :data-user-id="assigneeId"
    data-placement="left"
    class="gl-display-inline-block js-user-link"
  >
    <!-- use d-flex so that slot can be appropriately styled -->
    <span class="gl-display-flex">
      <assignee-avatar :user="user" :img-size="24" :issuable-type="issuableType" />
      <slot></slot>
    </span>
  </gl-link>
</template>
