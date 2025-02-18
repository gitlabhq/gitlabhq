<!-- eslint-disable vue/multi-word-component-names -->
<script>
import {
  GlBadge,
  GlLink,
  GlSkeletonLoader,
  GlTooltipDirective,
  GlTruncate,
  GlLoadingIcon,
  GlIcon,
  GlHoverLoadDirective,
  GlIntersectionObserver,
} from '@gitlab/ui';
import { escapeRegExp } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import paginatedTreeQuery from 'shared_queries/repository/paginated_tree.query.graphql';
import { buildURLwithRefType, joinPaths } from '~/lib/utils/url_utility';
import { TREE_PAGE_SIZE, ROW_APPEAR_DELAY } from '~/repository/constants';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import blobInfoQuery from 'shared_queries/repository/blob_info.query.graphql';
import getRefMixin from '../../mixins/get_ref';
import { getRefType } from '../../utils/ref_type';

export default {
  components: {
    GlBadge,
    GlLink,
    GlSkeletonLoader,
    GlLoadingIcon,
    GlIcon,
    GlTruncate,
    TimeagoTooltip,
    FileIcon,
    GlIntersectionObserver,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlHoverLoad: GlHoverLoadDirective,
    SafeHtml,
  },
  mixins: [getRefMixin],
  inject: ['refType'],
  props: {
    commitInfo: {
      type: Object,
      required: false,
      default: null,
    },
    rowNumber: {
      type: Number,
      required: false,
      default: null,
    },
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
      hasRowAppeared: false,
      delayedRowAppear: null,
    };
  },
  computed: {
    commitData() {
      return this.commitInfo;
    },
    routerLinkTo() {
      if (this.isBlob) {
        return buildURLwithRefType({
          path: joinPaths('/-/blob', this.escapedRef, encodeURI(this.path)),
          refType: this.refType,
        });
      }
      if (this.isFolder) {
        return buildURLwithRefType({
          path: joinPaths('/-/tree', this.escapedRef, encodeURI(this.path)),
          refType: this.refType,
        });
      }
      return null;
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
      return this.isFolder || this.isBlob ? 'router-link' : 'a';
    },
    fullPath() {
      return this.path.replace(new RegExp(`^${escapeRegExp(this.currentPath)}/`), '');
    },
    shortSha() {
      return this.sha.slice(0, 8);
    },
    hasLockLabel() {
      return this.commitData && this.commitData.lockLabel;
    },
    showSkeletonLoader() {
      return !this.commitData && this.hasRowAppeared;
    },
  },
  methods: {
    handlePreload() {
      return this.isFolder ? this.loadFolder() : this.loadBlob();
    },
    loadFolder() {
      this.apolloQuery(paginatedTreeQuery, {
        projectPath: this.projectPath,
        ref: this.ref,
        refType: getRefType(this.refType),
        path: this.path,
        nextPageCursor: '',
        pageSize: TREE_PAGE_SIZE,
      });
    },
    loadBlob() {
      this.apolloQuery(blobInfoQuery, {
        projectPath: this.projectPath,
        filePath: [this.path],
        ref: this.ref,
        refType: getRefType(this.refType),
        shouldFetchRawText: true,
      });
    },
    apolloQuery(query, variables) {
      this.$apollo.query({ query, variables });
    },
    rowAppeared() {
      this.hasRowAppeared = true;

      if (this.commitInfo) {
        return;
      }

      this.delayedRowAppear = setTimeout(
        () => this.$emit('row-appear', this.rowNumber),
        ROW_APPEAR_DELAY,
      );
    },
    rowDisappeared() {
      clearTimeout(this.delayedRowAppear);
      this.hasRowAppeared = false;
    },
  },
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
};
</script>

<template>
  <tr class="tree-item">
    <th class="tree-item-file-name gl-relative gl-cursor-default gl-font-normal" scope="row">
      <component
        :is="linkComponent"
        ref="link"
        v-gl-hover-load="handlePreload"
        :title="fullPath"
        :to="routerLinkTo"
        :href="url"
        :class="{
          'is-submodule': isSubmodule,
        }"
        class="tree-item-link gl-inline-flex gl-min-w-0 gl-max-w-full"
        data-testid="file-name-link"
      >
        <file-icon
          :file-name="fullPath"
          :file-mode="mode"
          :folder="isFolder"
          :submodule="isSubmodule"
          :loading="path === loadingPath"
          css-classes="gl-relative file-icon"
          class="gl-relative gl-mr-2 gl-text-secondary"
        /><gl-truncate
          :text="fullPath"
          position="end"
          class="gl-min-w-0 gl-grow hover:gl-underline"
          with-tooltip
        />
      </component>
      <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
      <gl-badge v-if="lfsOid" variant="muted" data-testid="label-lfs">LFS</gl-badge>
      <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
      <template v-if="isSubmodule">
        @ <gl-link :href="submoduleTreeUrl" class="commit-sha">{{ shortSha }}</gl-link>
      </template>
      <gl-icon
        v-if="hasLockLabel"
        v-gl-tooltip
        :title="commitData.lockLabel"
        name="lock"
        :size="12"
      />
    </th>
    <td class="tree-commit cursor-default gl-hidden sm:gl-table-cell">
      <gl-link
        v-if="commitData"
        v-safe-html:[$options.safeHtmlConfig]="commitData.titleHtml"
        :href="commitData.commitPath"
        :title="commitData.message"
        class="str-truncated-100 tree-commit-link gl-text-subtle"
      />
      <gl-intersection-observer @appear="rowAppeared" @disappear="rowDisappeared">
        <gl-skeleton-loader v-if="showSkeletonLoader" :lines="1" />
      </gl-intersection-observer>
    </td>
    <td class="tree-time-ago cursor-default gl-text-right gl-text-subtle">
      <gl-intersection-observer @appear="rowAppeared" @disappear="rowDisappeared">
        <timeago-tooltip v-if="commitData" :time="commitData.committedDate" />
      </gl-intersection-observer>
      <gl-skeleton-loader v-if="showSkeletonLoader" :lines="1" />
    </td>
  </tr>
</template>
