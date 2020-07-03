<script>
import { GlTooltipDirective, GlIcon, GlSprintf } from '@gitlab/ui';
import { n__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ListItem from '../list_item.vue';
import DeleteButton from '../delete_button.vue';

import {
  ASYNC_DELETE_IMAGE_ERROR_MESSAGE,
  LIST_DELETE_BUTTON_DISABLED,
  REMOVE_REPOSITORY_LABEL,
  ROW_SCHEDULED_FOR_DELETION,
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
    ASYNC_DELETE_IMAGE_ERROR_MESSAGE,
  },
  computed: {
    encodedItem() {
      const params = JSON.stringify({
        name: this.item.path,
        tags_path: this.item.tags_path,
        id: this.item.id,
      });
      return window.btoa(params);
    },
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
        class="gl-text-black-normal gl-font-weight-bold"
        data-testid="detailsLink"
        :to="{ name: 'details', params: { id: encodedItem } }"
      >
        {{ item.path }}
      </router-link>
      <clipboard-button
        v-if="item.location"
        :disabled="item.deleting"
        :text="item.location"
        :title="item.location"
        css-class="btn-default btn-transparent btn-clipboard gl-text-gray-500"
      />
      <gl-icon
        v-if="item.failedDelete"
        v-gl-tooltip="{ title: $options.i18n.ASYNC_DELETE_IMAGE_ERROR_MESSAGE }"
        name="warning"
        class="text-warning"
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
