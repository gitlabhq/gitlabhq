<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import permalinkPathQuery from '~/repository/queries/permalink_path.query.graphql';
import { logError } from '~/lib/logger';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import PermalinkDropdownItem from './permalink_dropdown_item.vue';

export const i18n = {
  dropdownLabel: __('Actions'),
  compare: __('Compare'),
};

export default {
  i18n,
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    PermalinkDropdownItem,
  },
  directives: {
    GlTooltipDirective,
  },
  inject: ['comparePath'],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: false,
      default: '',
    },
    currentRef: {
      type: String,
      required: true,
    },
  },
  apollo: {
    permalinkPath: {
      query: permalinkPathQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        const result = data?.project?.repository?.paginatedTree?.nodes[0]?.permalinkPath;
        return result;
      },
      error(error) {
        logError(`Failed to fetch permalink. See exception details for more information.`, error);
        Sentry.captureException(error);
      },
    },
  },
  data() {
    return {
      permalinkPath: '',
    };
  },
  computed: {
    compareItem() {
      return {
        text: i18n.compare,
        href: this.comparePath,
        extraAttrs: {
          'data-testid': 'tree-compare-control',
          rel: 'nofollow',
        },
      };
    },
    queryVariables() {
      return {
        fullPath: this.fullPath,
        path: this.path,
        ref: this.currentRef,
      };
    },
  },
  watch: {
    queryVariables: {
      handler() {
        this.$apollo.queries.permalinkPath.refetch();
      },
      deep: true,
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    v-gl-tooltip-directive="$options.i18n.dropdownLabel"
    no-caret
    icon="ellipsis_v"
    data-testid="repository-overflow-menu"
    placement="bottom-end"
    category="tertiary"
    :toggle-text="$options.i18n.dropdownLabel"
    text-sr-only
  >
    <permalink-dropdown-item
      v-if="permalinkPath"
      :permalink-path="permalinkPath"
      source="repository"
    />
    <gl-disclosure-dropdown-item v-if="comparePath" :item="compareItem" class="shortcuts-compare" />
  </gl-disclosure-dropdown>
</template>
