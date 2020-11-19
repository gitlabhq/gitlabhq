<script>
import { GlTooltipDirective, GlIcon, GlSprintf } from '@gitlab/ui';
import { n__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import DeleteButton from '../delete_button.vue';

import {
  ASYNC_DELETE_IMAGE_ERROR_MESSAGE,
  LIST_DELETE_BUTTON_DISABLED,
  REMOVE_REPOSITORY_LABEL,
  ROW_SCHEDULED_FOR_DELETION,
  CLEANUP_TIMED_OUT_ERROR_MESSAGE,
} from '../../constants/index';

export default {
  name: 'ImageListrow',
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
      return !this.item.destroy_path || this.item.deleting;
    },
    tagsCountText() {
      return n__(
        'ContainerRegistry|%{count} Tag',
        'ContainerRegistry|%{count} Tags',
        this.item.tags_count,
      );
    },
    warningIconText() {
      if (this.item.failedDelete) {
        return ASYNC_DELETE_IMAGE_ERROR_MESSAGE;
      } else if (this.item.cleanup_policy_started_at) {
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
      disabled: !item.deleting,
      title: $options.i18n.ROW_SCHEDULED_FOR_DELETION,
    }"
    v-bind="$attrs"
    :disabled="item.deleting"
  >
    <template #left-primary>
      <router-link
        class="gl-text-body gl-font-weight-bold"
        data-testid="details-link"
        :to="{ name: 'details', params: { id: item.id } }"
      >
        {{ item.path }}
      </router-link>
      <clipboard-button
        v-if="item.location"
        :disabled="item.deleting"
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
            {{ item.tags_count }}
          </template>
        </gl-sprintf>
      </span>
    </template>
    <template #right-action>
      <delete-button
        :title="$options.i18n.REMOVE_REPOSITORY_LABEL"
        :disabled="disabledDelete"
        :tooltip-disabled="Boolean(item.destroy_path)"
        :tooltip-title="$options.i18n.LIST_DELETE_BUTTON_DISABLED"
        @delete="$emit('delete', item)"
      />
    </template>
  </list-item>
</template>
