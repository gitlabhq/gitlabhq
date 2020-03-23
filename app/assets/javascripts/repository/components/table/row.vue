<script>
import { escapeRegExp } from 'lodash';
import { GlBadge, GlLink, GlSkeletonLoading, GlTooltipDirective, GlLoadingIcon } from '@gitlab/ui';
import { escapeFileUrl } from '~/lib/utils/url_utility';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import Icon from '~/vue_shared/components/icon.vue';
import { getIconName } from '../../utils/icon';
import getRefMixin from '../../mixins/get_ref';
import getCommit from '../../queries/getCommit.query.graphql';

export default {
  components: {
    GlBadge,
    GlLink,
    GlSkeletonLoading,
    GlLoadingIcon,
    TimeagoTooltip,
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  apollo: {
    commit: {
      query: getCommit,
      variables() {
        return {
          fileName: this.name,
          type: this.type,
          path: this.currentPath,
          projectPath: this.projectPath,
        };
      },
    },
  },
  mixins: [getRefMixin],
  props: {
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
    routerLinkTo() {
      return this.isFolder
        ? { path: `/-/tree/${escape(this.ref)}/${escapeFileUrl(this.path)}` }
        : null;
    },
    iconName() {
      return `fa-${getIconName(this.type, this.path)}`;
    },
    isFolder() {
      return this.type === 'tree';
    },
    isSubmodule() {
      return this.type === 'commit';
    },
    linkComponent() {
      return this.isFolder ? 'router-link' : 'a';
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
};
</script>

<template>
  <tr class="tree-item">
    <td class="tree-item-file-name cursor-default position-relative">
      <gl-loading-icon
        v-if="path === loadingPath"
        size="sm"
        inline
        class="d-inline-block align-text-bottom fa-fw"
      />
      <component
        :is="linkComponent"
        ref="link"
        :to="routerLinkTo"
        :href="url"
        :class="{
          'is-submodule': isSubmodule,
        }"
        class="tree-item-link str-truncated"
        data-qa-selector="file_name_link"
      >
        <i
          v-if="!loadingPath"
          :aria-label="type"
          role="img"
          :class="iconName"
          class="fa fa-fw mr-1"
        ></i
        ><span class="position-relative">{{ fullPath }}</span>
      </component>
      <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
      <gl-badge v-if="lfsOid" variant="default" class="label-lfs ml-1">LFS</gl-badge>
      <template v-if="isSubmodule">
        @ <gl-link :href="submoduleTreeUrl" class="commit-sha">{{ shortSha }}</gl-link>
      </template>
      <icon
        v-if="hasLockLabel"
        v-gl-tooltip
        :title="commit.lockLabel"
        name="lock"
        :size="12"
        class="ml-2 vertical-align-middle"
      />
    </td>
    <td class="d-none d-sm-table-cell tree-commit cursor-default">
      <gl-link
        v-if="commit"
        :href="commit.commitPath"
        :title="commit.message"
        class="str-truncated-100 tree-commit-link"
      >
        {{ commit.message }}
      </gl-link>
      <gl-skeleton-loading v-else :lines="1" class="h-auto" />
    </td>
    <td class="tree-time-ago text-right cursor-default">
      <timeago-tooltip v-if="commit" :time="commit.committedDate" />
      <gl-skeleton-loading v-else :lines="1" class="ml-auto h-auto w-50" />
    </td>
  </tr>
</template>
