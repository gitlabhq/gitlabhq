<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlTooltipDirective,
  GlIcon,
} from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import { generateRouterParams } from '~/repository/utils/ref_switcher_utils';
import RefSelector from '~/ref/components/ref_selector.vue';
import { __ } from '~/locale';
import OpenMrBadge from '~/badges/components/open_mr_badge/open_mr_badge.vue';
import CommitFilteredSearch from './commit_filtered_search.vue';
import CommitListBreadcrumb from './commit_list_breadcrumb.vue';

export default {
  name: 'CommitHeader',
  components: {
    RefSelector,
    CommitFilteredSearch,
    CommitListBreadcrumb,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlIcon,
    OpenMrBadge,
  },
  directives: {
    GlTooltipDirective,
  },
  inject: [
    'projectRootPath',
    'projectFullPath',
    'projectId',
    'escapedRef',
    'refType',
    'rootRef',
    'browseFilesPath',
    'commitsFeedPath',
  ],
  computed: {
    currentPath() {
      return this.$route.params.path || '';
    },
    dropdownItems() {
      return [
        {
          text: __('Browse files'),
          icon: 'folder-open',
          href: this.browseFilesPath,
          extraAttrs: {
            'data-testid': 'browse-files-link',
          },
        },
        {
          text: __('Commits feed'),
          icon: 'rss',
          href: this.commitsFeedPath,
          extraAttrs: {
            'data-testid': 'commits-feed-link',
          },
        },
      ];
    },
    refSelectorQueryParams() {
      return {
        sort: 'updated_desc',
      };
    },
    refSelectorValue() {
      return this.refType ? joinPaths('refs', this.refType, this.escapedRef) : this.escapedRef;
    },
  },
  methods: {
    onRefChange(selectedRef) {
      const { path, query } = generateRouterParams(selectedRef, this.$route);
      this.$router.push({ path, query });
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-flex gl-items-center gl-gap-5">
      <ref-selector
        class="gl-max-w-26"
        data-testid="commits-ref-selector"
        :project-id="projectId"
        :value="refSelectorValue"
        :default-branch="rootRef"
        use-symbolic-ref-names
        :query-params="refSelectorQueryParams"
        @input="onRefChange"
      />
      <commit-list-breadcrumb class="gl-grow" />
    </div>

    <div class="gl-flex gl-items-center gl-justify-between">
      <h1 class="gl-text-size-h1">{{ __('Commits') }}</h1>

      <div class="gl-flex gl-items-baseline gl-gap-3">
        <open-mr-badge
          v-if="currentPath"
          :project-path="projectFullPath"
          :blob-path="currentPath"
          :current-ref="escapedRef"
        />
        <gl-disclosure-dropdown
          v-gl-tooltip-directive.hover="__('Actions')"
          no-caret
          icon="ellipsis_v"
          :toggle-text="__('Actions')"
          text-sr-only
          category="tertiary"
          placement="bottom-end"
        >
          <gl-disclosure-dropdown-item
            v-for="item in dropdownItems"
            :key="item.text"
            :item="item"
            v-bind="item.extraAttrs"
          >
            <template #list-item>
              <gl-icon :name="item.icon" class="gl-mr-2" variant="subtle" />
              {{ item.text }}
            </template>
          </gl-disclosure-dropdown-item>
        </gl-disclosure-dropdown>
      </div>
    </div>

    <commit-filtered-search @filter="$emit('filter', $event)" />
  </div>
</template>
