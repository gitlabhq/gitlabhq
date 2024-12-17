<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlIcon, GlTooltipDirective, GlSkeletonLoader } from '@gitlab/ui';
import permissionsQuery from 'shared_queries/design_management/design_permissions.query.graphql';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { __, s__, sprintf } from '~/locale';
import { TYPE_DESIGN } from '~/import/constants';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import { DESIGNS_ROUTE_NAME } from '../../router/constants';
import DeleteButton from '../delete_button.vue';
import DesignTodoButton from '../design_todo_button.vue';
import DesignNavigation from './design_navigation.vue';
import CloseButton from './close_button.vue';

export default {
  i18n: {
    downloadButtonLabel: s__('DesignManagement|Download design'),
    hideCommentsButtonLabel: s__('DesignManagement|Hide comments'),
    showCommentsButtonLabel: s__('DesignManagement|Show comments'),
  },
  components: {
    GlButton,
    GlIcon,
    GlSkeletonLoader,
    DesignNavigation,
    DeleteButton,
    DesignTodoButton,
    CloseButton,
    ImportedBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  inject: {
    projectPath: {
      default: '',
    },
    issueIid: {
      default: '',
    },
  },
  props: {
    id: {
      type: String,
      required: true,
    },
    isDeleting: {
      type: Boolean,
      required: true,
    },
    filename: {
      type: String,
      required: false,
      default: '',
    },
    updatedAt: {
      type: String,
      required: false,
      default: null,
    },
    updatedBy: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isLatestVersion: {
      type: Boolean,
      required: true,
    },
    image: {
      type: String,
      required: false,
      default: '',
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    design: {
      type: Object,
      required: true,
    },
    isSidebarOpen: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isLoggedIn: isLoggedIn(),
      permissions: {
        createDesign: false,
      },
    };
  },
  apollo: {
    permissions: {
      query: permissionsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.issueIid,
        };
      },
      update: (data) => data.project.issue.userPermissions,
    },
  },
  computed: {
    updatedText() {
      return sprintf(__('Updated %{updated_at} by %{updated_by}'), {
        updated_at: this.timeFormatted(this.updatedAt),
        updated_by: this.updatedBy.name,
      });
    },
    canDeleteDesign() {
      return this.permissions.createDesign;
    },
    issueTitle() {
      return this.design.issue.title;
    },
    isImported() {
      return this.design.imported;
    },
    toggleCommentsButtonLabel() {
      return this.isSidebarOpen
        ? this.$options.i18n.hideCommentsButtonLabel
        : this.$options.i18n.showCommentsButtonLabel;
    },
  },
  DESIGNS_ROUTE_NAME,
  TYPE_DESIGN,
};
</script>

<template>
  <header
    class="js-design-header gl-border-b gl-flex gl-max-w-full gl-flex-col gl-justify-between gl-bg-white gl-py-4 gl-pl-5 md:gl-flex-row md:gl-items-center"
  >
    <div class="gl-mb-3 gl-flex gl-flex-row gl-items-center gl-overflow-hidden md:gl-mb-0">
      <div class="gl-mr-3 gl-flex gl-overflow-hidden">
        <gl-skeleton-loader v-if="isLoading" :lines="1" />
        <h2 v-else class="gl-m-0 gl-flex gl-items-center gl-overflow-hidden gl-text-base">
          <span class="gl-truncate gl-text-heading gl-no-underline">
            {{ issueTitle }}
          </span>
          <gl-icon name="chevron-right" class="gl-shrink-0" variant="disabled" />
          <span class="gl-truncate gl-font-normal">{{ filename }}</span>
          <imported-badge
            v-if="isImported"
            :importable-type="$options.TYPE_DESIGN"
            class="gl-ml-2"
          />
        </h2>
        <small v-if="updatedAt" class="gl-text-subtle">{{ updatedText }}</small>
      </div>
      <close-button class="gl-ml-auto md:gl-hidden" />
    </div>
    <div class="gl-mr-5 gl-flex gl-shrink-0 md:gl-ml-auto md:gl-flex-row">
      <design-todo-button
        v-if="isLoggedIn"
        :design="design"
        class="gl-ml-0 md:gl-ml-3"
        @error="$emit('todoError', $event)"
      />
      <gl-button
        v-gl-tooltip.bottom
        category="tertiary"
        class="gl-ml-2"
        :href="image"
        icon="download"
        :title="$options.i18n.downloadButtonLabel"
        :aria-label="$options.i18n.downloadButtonLabel"
      />
      <delete-button
        v-if="isLatestVersion && canDeleteDesign"
        v-gl-tooltip.bottom
        class="gl-ml-2"
        :is-deleting="isDeleting"
        button-variant="default"
        button-icon="archive"
        button-category="tertiary"
        :title="s__('DesignManagement|Archive design')"
        @delete-selected-designs="$emit('delete')"
      />
      <gl-button
        v-gl-tooltip.bottom
        category="tertiary"
        icon="comments"
        :title="toggleCommentsButtonLabel"
        :aria-label="toggleCommentsButtonLabel"
        class="gl-ml-2 gl-mr-6"
        data-testid="toggle-design-sidebar"
        @click="$emit('toggle-sidebar')"
      />
      <design-navigation :id="id" class="gl-ml-auto" />
    </div>
    <close-button class="gl-hidden md:gl-flex" />
  </header>
</template>
