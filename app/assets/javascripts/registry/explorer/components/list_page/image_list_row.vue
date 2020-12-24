<script>
import { GlTooltipDirective, GlIcon, GlSprintf } from '@gitlab/ui';
import { n__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import DeleteButton from '../delete_button.vue';

import {
  ASYNC_DELETE_IMAGE_ERROR_MESSAGE,
  LIST_DELETE_BUTTON_DISABLED,
  REMOVE_REPOSITORY_LABEL,
  ROW_SCHEDULED_FOR_DELETION,
  CLEANUP_TIMED_OUT_ERROR_MESSAGE,
  IMAGE_DELETE_SCHEDULED_STATUS,
  IMAGE_FAILED_DELETED_STATUS,
} from '../../constants/index';

export default {
  name: 'ImageListRow',
  components: {
    ClipboardButton,
    DeleteButton,
    GlSprintf,
    GlIcon,
    ListItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    LIST_DELETE_BUTTON_DISABLED,
    REMOVE_REPOSITORY_LABEL,
    ROW_SCHEDULED_FOR_DELETION,
  },
  computed: {
    disabledDelete() {
      return !this.item.canDelete || this.deleting;
    },
    id() {
      return getIdFromGraphQLId(this.item.id);
    },
    deleting() {
      return this.item.status === IMAGE_DELETE_SCHEDULED_STATUS;
    },
    failedDelete() {
      return this.item.status === IMAGE_FAILED_DELETED_STATUS;
    },
    tagsCountText() {
      return n__(
        'ContainerRegistry|%{count} Tag',
        'ContainerRegistry|%{count} Tags',
        this.item.tagsCount,
      );
    },
    warningIconText() {
      if (this.failedDelete) {
        return ASYNC_DELETE_IMAGE_ERROR_MESSAGE;
      }
      if (this.item.expirationPolicyStartedAt) {
        return CLEANUP_TIMED_OUT_ERROR_MESSAGE;
      }
      return null;
    },
  },
};
</script>

<template>
  <list-item
    v-gl-tooltip="{
      placement: 'left',
      disabled: !deleting,
      title: $options.i18n.ROW_SCHEDULED_FOR_DELETION,
    }"
    v-bind="$attrs"
    :disabled="deleting"
  >
    <template #left-primary>
      <router-link
        class="gl-text-body gl-font-weight-bold"
        data-testid="details-link"
        :to="{ name: 'details', params: { id } }"
      >
        {{ item.path }}
      </router-link>
      <clipboard-button
        v-if="item.location"
        :disabled="deleting"
        :text="item.location"
        :title="item.location"
        category="tertiary"
      />
      <gl-icon
        v-if="warningIconText"
        v-gl-tooltip="{ title: warningIconText }"
        data-testid="warning-icon"
        name="warning"
        class="gl-text-orange-500"
      />
    </template>
    <template #left-secondary>
      <span class="gl-display-flex gl-align-items-center" data-testid="tagsCount">
        <gl-icon name="tag" class="gl-mr-2" />
        <gl-sprintf :message="tagsCountText">
          <template #count>
            {{ item.tagsCount }}
          </template>
        </gl-sprintf>
      </span>
    </template>
    <template #right-action>
      <delete-button
        :title="$options.i18n.REMOVE_REPOSITORY_LABEL"
        :disabled="disabledDelete"
        :tooltip-disabled="item.canDelete"
        :tooltip-title="$options.i18n.LIST_DELETE_BUTTON_DISABLED"
        @delete="$emit('delete', item)"
      />
    </template>
  </list-item>
</template>
