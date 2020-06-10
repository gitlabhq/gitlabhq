<script>
import { GlTooltipDirective, GlButton, GlIcon, GlSprintf } from '@gitlab/ui';
import { n__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

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
    GlButton,
    GlSprintf,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    showTopBorder: {
      type: Boolean,
      default: false,
      required: false,
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
  <div
    v-gl-tooltip="{
      placement: 'left',
      disabled: !item.deleting,
      title: $options.i18n.ROW_SCHEDULED_FOR_DELETION,
    }"
  >
    <div
      class="gl-display-flex gl-justify-content-space-between gl-align-items-center gl-py-2 gl-px-1 gl-border-gray-200 gl-border-b-solid gl-border-b-1 gl-py-4 "
      :class="{
        'gl-border-t-solid gl-border-t-1': showTopBorder,
        'disabled-content': item.deleting,
      }"
    >
      <div class="gl-display-flex gl-flex-direction-column">
        <div class="gl-display-flex gl-align-items-center">
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
            v-gl-tooltip
            :title="$options.i18n.ASYNC_DELETE_IMAGE_ERROR_MESSAGE"
            name="warning"
            class="text-warning"
          />
        </div>
        <div class="gl-font-sm gl-text-gray-500">
          <span class="gl-display-flex gl-align-items-center" data-testid="tagsCount">
            <gl-icon name="tag" class="gl-mr-2" />
            <gl-sprintf :message="tagsCountText">
              <template #count>
                {{ item.tags_count }}
              </template>
            </gl-sprintf>
          </span>
        </div>
      </div>
      <div
        v-gl-tooltip="{
          disabled: item.destroy_path,
          title: $options.i18n.LIST_DELETE_BUTTON_DISABLED,
        }"
        class="d-none d-sm-block"
        data-testid="deleteButtonWrapper"
      >
        <gl-button
          v-gl-tooltip
          data-testid="deleteImageButton"
          :disabled="disabledDelete"
          :title="$options.i18n.REMOVE_REPOSITORY_LABEL"
          :aria-label="$options.i18n.REMOVE_REPOSITORY_LABEL"
          category="secondary"
          variant="danger"
          icon="remove"
          @click="$emit('delete', item)"
        />
      </div>
    </div>
  </div>
</template>
