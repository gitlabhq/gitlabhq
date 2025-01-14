<script>
import { GlButton, GlTooltipDirective, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import ProtectedBadge from '~/vue_shared/components/badges/protected_badge.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { n__, s__ } from '~/locale';
import Tracking from '~/tracking';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import { joinPaths } from '~/lib/utils/url_utility';
import PublishMessage from '~/packages_and_registries/shared/components/publish_message.vue';
import {
  LIST_DELETE_BUTTON_DISABLED,
  LIST_DELETE_BUTTON_DISABLED_FOR_MIGRATION,
  REMOVE_REPOSITORY_LABEL,
  ROW_SCHEDULED_FOR_DELETION,
  IMAGE_DELETE_SCHEDULED_STATUS,
  IMAGE_MIGRATING_STATE,
  COPY_IMAGE_PATH_TITLE,
  IMAGE_FULL_PATH_LABEL,
  TRACKING_ACTION_CLICK_SHOW_FULL_PATH,
  TRACKING_LABEL_REGISTRY_IMAGE_LIST,
} from '../../constants/index';
import DeleteButton from '../delete_button.vue';
import CleanupStatus from './cleanup_status.vue';

export default {
  name: 'ImageListRow',
  components: {
    ClipboardButton,
    DeleteButton,
    GlSprintf,
    GlButton,
    ListItem,
    GlSkeletonLoader,
    CleanupStatus,
    PublishMessage,

    ProtectedBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  inject: ['config'],
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
    expirationPolicy: {
      type: Object,
      default: () => ({}),
      required: false,
    },
  },
  i18n: {
    REMOVE_REPOSITORY_LABEL,
    ROW_SCHEDULED_FOR_DELETION,
    COPY_IMAGE_PATH_TITLE,
    IMAGE_FULL_PATH_LABEL,
    badgeProtectedTooltipText: s__(
      'ContainerRegistry|A protection rule exists for this container repository.',
    ),
  },
  data() {
    return {
      showFullPath: false,
    };
  },
  computed: {
    disabledDelete() {
      return (
        !this.item.userPermissions.destroyContainerRepository || this.deleting || this.migrating
      );
    },
    id() {
      return getIdFromGraphQLId(this.item.id);
    },
    deleting() {
      return this.item.status === IMAGE_DELETE_SCHEDULED_STATUS;
    },
    migrating() {
      return this.item.migrationState === IMAGE_MIGRATING_STATE;
    },
    tagsCountText() {
      return n__(
        'ContainerRegistry|%{count} tag',
        'ContainerRegistry|%{count} tags',
        this.item.tagsCount,
      );
    },
    imageName() {
      if (this.showFullPath) {
        return this.item.path;
      }
      const projectPath = this.item?.project?.path?.toLowerCase() ?? '';
      if (this.item.name) {
        return joinPaths(projectPath, this.item.name);
      }
      return projectPath;
    },
    deleteButtonTooltipTitle() {
      return this.migrating
        ? LIST_DELETE_BUTTON_DISABLED_FOR_MIGRATION
        : LIST_DELETE_BUTTON_DISABLED;
    },
    projectName() {
      return this.config.isGroupPage ? this.item.project?.name : '';
    },
    projectUrl() {
      return this.config.isGroupPage ? this.item.project?.webUrl : '';
    },
    showBadgeProtected() {
      return Boolean(this.item.protectionRuleExists);
    },
  },
  methods: {
    hideButton() {
      this.showFullPath = true;
      this.$refs.imageName.$el.focus();
      this.track(TRACKING_ACTION_CLICK_SHOW_FULL_PATH, {
        label: TRACKING_LABEL_REGISTRY_IMAGE_LIST,
      });
    },
  },
};
</script>

<template>
  <list-item v-bind="$attrs">
    <template #left-primary>
      <gl-button
        v-if="!showFullPath"
        v-gl-tooltip="{
          placement: 'top',
          title: $options.i18n.IMAGE_FULL_PATH_LABEL,
        }"
        icon="ellipsis_h"
        size="small"
        class="gl-mr-2"
        :aria-label="$options.i18n.IMAGE_FULL_PATH_LABEL"
        @click="hideButton"
      />
      <span v-if="deleting" class="gl-text-subtle">{{ imageName }}</span>
      <router-link
        v-else
        ref="imageName"
        class="gl-font-bold gl-text-default"
        data-testid="details-link"
        :to="{ name: 'details', params: { id } }"
      >
        {{ imageName }}
      </router-link>
      <clipboard-button
        v-if="item.location"
        :disabled="deleting"
        :text="item.location"
        :title="$options.i18n.COPY_IMAGE_PATH_TITLE"
        category="tertiary"
        class="gl-ml-2"
        size="small"
      />
    </template>
    <template #left-secondary>
      <template v-if="!metadataLoading">
        <span v-if="deleting">{{ $options.i18n.ROW_SCHEDULED_FOR_DELETION }}</span>
        <template v-else>
          <span class="gl-flex gl-items-center" data-testid="tags-count">
            <gl-sprintf :message="tagsCountText">
              <template #count>
                {{ item.tagsCount }}
              </template>
            </gl-sprintf>
          </span>

          <cleanup-status
            v-if="item.expirationPolicyCleanupStatus"
            :status="item.expirationPolicyCleanupStatus"
            :expiration-policy="expirationPolicy"
          />

          <protected-badge
            v-if="showBadgeProtected"
            :tooltip-text="$options.i18n.badgeProtectedTooltipText"
          />
        </template>
      </template>

      <div v-else class="gl-w-full">
        <gl-skeleton-loader :width="900" :height="16" preserve-aspect-ratio="xMinYMax meet">
          <circle cx="6" cy="8" r="6" />
          <rect x="16" y="4" width="100" height="8" rx="4" />
        </gl-skeleton-loader>
      </div>
    </template>
    <template #right-primary> &nbsp; </template>
    <template #right-secondary>
      <publish-message
        :project-name="projectName"
        :project-url="projectUrl"
        :publish-date="item.createdAt"
      />
    </template>

    <template #right-action>
      <delete-button
        :title="$options.i18n.REMOVE_REPOSITORY_LABEL"
        :disabled="disabledDelete"
        :tooltip-disabled="!disabledDelete"
        :tooltip-link="config.containerRegistryImportingHelpPagePath"
        :tooltip-title="deleteButtonTooltipTitle"
        @delete="$emit('delete', item)"
      />
    </template>
  </list-item>
</template>
