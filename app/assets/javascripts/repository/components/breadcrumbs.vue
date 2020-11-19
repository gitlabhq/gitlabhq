<script>
import {
  GlDropdown,
  GlDropdownDivider,
  GlDropdownSectionHeader,
  GlDropdownItem,
  GlIcon,
} from '@gitlab/ui';
import permissionsQuery from 'shared_queries/repository/permissions.query.graphql';
import { joinPaths, escapeFileUrl } from '~/lib/utils/url_utility';
import { __ } from '../../locale';
import getRefMixin from '../mixins/get_ref';
import projectShortPathQuery from '../queries/project_short_path.query.graphql';
import projectPathQuery from '../queries/project_path.query.graphql';

const ROW_TYPES = {
  header: 'header',
  divider: 'divider',
};

export default {
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownSectionHeader,
    GlDropdownItem,
    GlIcon,
  },
  apollo: {
    projectShortPath: {
      query: projectShortPathQuery,
    },
    projectPath: {
      query: projectPathQuery,
    },
    userPermissions: {
      query: permissionsQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update: data => data.project?.userPermissions,
      error(error) {
        throw error;
      },
    },
  },
  mixins: [getRefMixin],
  props: {
    currentPath: {
      type: String,
      required: false,
      default: '',
    },
    canCollaborate: {
      type: Boolean,
      required: false,
      default: false,
    },
    canEditTree: {
      type: Boolean,
      required: false,
      default: false,
    },
    newBranchPath: {
      type: String,
      required: false,
      default: null,
    },
    newTagPath: {
      type: String,
      required: false,
      default: null,
    },
    newBlobPath: {
      type: String,
      required: false,
      default: null,
    },
    forkNewBlobPath: {
      type: String,
      required: false,
      default: null,
    },
    forkNewDirectoryPath: {
      type: String,
      required: false,
      default: null,
    },
    forkUploadBlobPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      projectShortPath: '',
      projectPath: '',
      userPermissions: {},
    };
  },
  computed: {
    pathLinks() {
      return this.currentPath
        .split('/')
        .filter(p => p !== '')
        .reduce(
          (acc, name, i) => {
            const path = joinPaths(i > 0 ? acc[i].path : '', escapeFileUrl(name));

            return acc.concat({
              name,
              path,
              to: `/-/tree/${joinPaths(this.escapedRef, path)}`,
            });
          },
          [
            {
              name: this.projectShortPath,
              path: '/',
              to: `/-/tree/${this.escapedRef}/`,
            },
          ],
        );
    },
    canCreateMrFromFork() {
      return this.userPermissions.forkProject && this.userPermissions.createMergeRequestIn;
    },
    dropdownItems() {
      const items = [];

      if (this.canEditTree) {
        items.push(
          {
            type: ROW_TYPES.header,
            text: __('This directory'),
          },
          {
            attrs: {
              href: `${this.newBlobPath}/${
                this.currentPath ? encodeURIComponent(this.currentPath) : ''
              }`,
              class: 'qa-new-file-option',
            },
            text: __('New file'),
          },
          {
            attrs: {
              href: '#modal-upload-blob',
              'data-target': '#modal-upload-blob',
              'data-toggle': 'modal',
            },
            text: __('Upload file'),
          },
          {
            attrs: {
              href: '#modal-create-new-dir',
              'data-target': '#modal-create-new-dir',
              'data-toggle': 'modal',
            },
            text: __('New directory'),
          },
        );
      } else if (this.canCreateMrFromFork) {
        items.push(
          {
            attrs: {
              href: this.forkNewBlobPath,
              'data-method': 'post',
            },
            text: __('New file'),
          },
          {
            attrs: {
              href: this.forkUploadBlobPath,
              'data-method': 'post',
            },
            text: __('Upload file'),
          },
          {
            attrs: {
              href: this.forkNewDirectoryPath,
              'data-method': 'post',
            },
            text: __('New directory'),
          },
        );
      }

      if (this.userPermissions?.pushCode) {
        items.push(
          {
            type: ROW_TYPES.divider,
          },
          {
            type: ROW_TYPES.header,
            text: __('This repository'),
          },
          {
            attrs: {
              href: this.newBranchPath,
            },
            text: __('New branch'),
          },
          {
            attrs: {
              href: this.newTagPath,
            },
            text: __('New tag'),
          },
        );
      }

      return items;
    },
    renderAddToTreeDropdown() {
      return this.canCollaborate || this.canCreateMrFromFork;
    },
  },
  methods: {
    isLast(i) {
      return i === this.pathLinks.length - 1;
    },
    getComponent(type) {
      switch (type) {
        case ROW_TYPES.divider:
          return 'gl-dropdown-divider';
        case ROW_TYPES.header:
          return 'gl-dropdown-section-header';
        default:
          return 'gl-dropdown-item';
      }
    },
  },
};
</script>

<template>
  <nav :aria-label="__('Files breadcrumb')">
    <ol class="breadcrumb repo-breadcrumb">
      <li v-for="(link, i) in pathLinks" :key="i" class="breadcrumb-item">
        <router-link :to="link.to" :aria-current="isLast(i) ? 'page' : null">
          {{ link.name }}
        </router-link>
      </li>
      <li v-if="renderAddToTreeDropdown" class="breadcrumb-item">
        <gl-dropdown toggle-class="add-to-tree qa-add-to-tree gl-ml-2">
          <template #button-content>
            <span class="sr-only">{{ __('Add to tree') }}</span>
            <gl-icon name="plus" :size="16" class="float-left" />
            <gl-icon name="chevron-down" :size="16" class="float-left" />
          </template>
          <template v-for="(item, i) in dropdownItems">
            <component :is="getComponent(item.type)" :key="i" v-bind="item.attrs">
              {{ item.text }}
            </component>
          </template>
        </gl-dropdown>
      </li>
    </ol>
  </nav>
</template>
