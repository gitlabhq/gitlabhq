<script>
/* eslint-disable vue/no-v-html */
import {
  GlBadge,
  GlLink,
  GlDeprecatedSkeletonLoading as GlSkeletonLoading,
  GlTooltipDirective,
  GlLoadingIcon,
  GlIcon,
  GlHoverLoadDirective,
} from '@gitlab/ui';
import { escapeRegExp } from 'lodash';
import filesQuery from 'shared_queries/repository/files.query.graphql';
import { escapeFileUrl } from '~/lib/utils/url_utility';
import { TREE_PAGE_SIZE } from '~/repository/constants';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import getRefMixin from '../../mixins/get_ref';
import blobInfoQuery from '../../queries/blob_info.query.graphql';
import commitQuery from '../../queries/commit.query.graphql';

export default {
  components: {
    GlBadge,
    GlLink,
    GlSkeletonLoading,
    GlLoadingIcon,
    GlIcon,
    TimeagoTooltip,
    FileIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlHoverLoad: GlHoverLoadDirective,
  },
  apollo: {
    commit: {
      query: commitQuery,
      variables() {
        return {
          fileName: this.name,
          type: this.type,
          path: this.currentPath,
          projectPath: this.projectPath,
          maxOffset: this.totalEntries,
        };
      },
    },
  },
  mixins: [getRefMixin, glFeatureFlagMixin()],
  props: {
    totalEntries: {
      type: Number,
      required: true,
    },
    id: {
      type: String,
      required: true,
    },
    sha: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    currentPath: {
      type: String,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
    mode: {
      type: String,
      required: false,
      default: '',
    },
    type: {
      type: String,
      required: true,
    },
    url: {
      type: String,
      required: false,
      default: null,
    },
    lfsOid: {
      type: String,
      required: false,
      default: null,
    },
    submoduleTreeUrl: {
      type: String,
      required: false,
      default: null,
    },
    loadingPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      commit: null,
    };
  },
  computed: {
    refactorBlobViewerEnabled() {
      return this.glFeatures.refactorBlobViewer;
    },
    routerLinkTo() {
      const blobRouteConfig = { path: `/-/blob/${this.escapedRef}/${escapeFileUrl(this.path)}` };
      const treeRouteConfig = { path: `/-/tree/${this.escapedRef}/${escapeFileUrl(this.path)}` };

      if (this.refactorBlobViewerEnabled && this.isBlob) {
        return blobRouteConfig;
      }

      return this.isFolder ? treeRouteConfig : null;
    },
    isBlob() {
      return this.type === 'blob';
    },
    isFolder() {
      return this.type === 'tree';
    },
    isSubmodule() {
      return this.type === 'commit';
    },
    linkComponent() {
      return this.isFolder || (this.refactorBlobViewerEnabled && this.isBlob) ? 'router-link' : 'a';
    },
    fullPath() {
      return this.path.replace(new RegExp(`^${escapeRegExp(this.currentPath)}/`), '');
    },
    shortSha() {
      return this.sha.slice(0, 8);
    },
    hasLockLabel() {
      return this.commit && this.commit.lockLabel;
    },
  },
  methods: {
    handlePreload() {
      return this.isFolder ? this.loadFolder() : this.loadBlob();
    },
    loadFolder() {
      this.apolloQuery(filesQuery, {
        projectPath: this.projectPath,
        ref: this.ref,
        path: this.path,
        nextPageCursor: '',
        pageSize: TREE_PAGE_SIZE,
      });
    },
    loadBlob() {
      if (!this.refactorBlobViewerEnabled) {
        return;
      }

      this.apolloQuery(blobInfoQuery, {
        projectPath: this.projectPath,
        filePath: this.path,
      });
    },
    apolloQuery(query, variables) {
      this.$apollo.query({ query, variables });
    },
  },
};
</script>

<template>
  <tr class="tree-item">
    <td class="tree-item-file-name cursor-default position-relative">
      <component
        :is="linkComponent"
        ref="link"
        v-gl-hover-load="handlePreload"
        v-gl-tooltip:tooltip-container
        :title="fullPath"
        :to="routerLinkTo"
        :href="url"
        :class="{
          'is-submodule': isSubmodule,
        }"
        class="tree-item-link str-truncated"
        data-qa-selector="file_name_link"
      >
        <file-icon
          :file-name="fullPath"
          :file-mode="mode"
          :folder="isFolder"
          :submodule="isSubmodule"
          :loading="path === loadingPath"
          css-classes="position-relative file-icon"
          class="mr-1 position-relative text-secondary"
        /><span class="position-relative">{{ fullPath }}</span>
      </component>
      <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
      <gl-badge v-if="lfsOid" variant="muted" size="sm" class="ml-1" data-qa-selector="label-lfs"
        >LFS</gl-badge
      >
      <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
      <template v-if="isSubmodule">
        @ <gl-link :href="submoduleTreeUrl" class="commit-sha">{{ shortSha }}</gl-link>
      </template>
      <gl-icon
        v-if="hasLockLabel"
        v-gl-tooltip
        :title="commit.lockLabel"
        name="lock"
        :size="12"
        class="ml-1"
      />
    </td>
    <td class="d-none d-sm-table-cell tree-commit cursor-default">
      <gl-link
        v-if="commit"
        :href="commit.commitPath"
        :title="commit.message"
        class="str-truncated-100 tree-commit-link"
        v-html="commit.titleHtml"
      />
      <gl-skeleton-loading v-else :lines="1" class="h-auto" />
    </td>
    <td class="tree-time-ago text-right cursor-default">
      <timeago-tooltip v-if="commit" :time="commit.committedDate" />
      <gl-skeleton-loading v-else :lines="1" class="ml-auto h-auto w-50" />
    </td>
  </tr>
</template>
