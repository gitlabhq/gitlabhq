<script>
import { GlTooltipDirective, GlIcon, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { n__ } from '~/locale';

import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import {
  ASYNC_DELETE_IMAGE_ERROR_MESSAGE,
  LIST_DELETE_BUTTON_DISABLED,
  REMOVE_REPOSITORY_LABEL,
  ROW_SCHEDULED_FOR_DELETION,
  CLEANUP_TIMED_OUT_ERROR_MESSAGE,
  IMAGE_DELETE_SCHEDULED_STATUS,
  IMAGE_FAILED_DELETED_STATUS,
  ROOT_IMAGE_TEXT,
} from '../../constants/index';
import DeleteButton from '../delete_button.vue';
import CleanupStatus from './cleanup_status.vue';

export default {
  name: 'ImageListRow',
  components: {
    ClipboardButton,
    DeleteButton,
    GlSprintf,
    GlIcon,
    ListItem,
    GlSkeletonLoader,
    CleanupStatus,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    metadataLoading: {
      type: Boolean,
      default: false,
      required: false,
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
    imageName() {
      return this.item.name ? this.item.path : `${this.item.path}/ ${ROOT_IMAGE_TEXT}`;
    },
    routerLinkEvent() {
      return this.deleting ? '' : 'click';
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
        data-qa-selector="registry_image_content"
        :event="routerLinkEvent"
        :to="{ name: 'details', params: { id } }"
      >
        {{ imageName }}
      </router-link>
      <clipboard-button
        v-if="item.location"
        :disabled="deleting"
        :text="item.location"
        :title="item.location"
        category="tertiary"
      />
    </template>
    <template #left-secondary>
      <template v-if="!metadataLoading">
        <span class="gl-display-flex gl-align-items-center" data-testid="tags-count">
          <gl-icon name="tag" class="gl-mr-2" />
          <gl-sprintf :message="tagsCountText">
            <template #count>
              {{ item.tagsCount }}
            </template>
          </gl-sprintf>
        </span>

        <cleanup-status
          v-if="item.expirationPolicyCleanupStatus"
          class="ml-2"
          :status="item.expirationPolicyCleanupStatus"
        />
      </template>

      <div v-else class="gl-w-full">
        <gl-skeleton-loader :width="900" :height="16" preserve-aspect-ratio="xMinYMax meet">
          <circle cx="6" cy="8" r="6" />
          <rect x="16" y="4" width="100" height="8" rx="4" />
        </gl-skeleton-loader>
      </div>
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
