<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { GlFormCheckbox, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import AjaxCache from '~/lib/utils/ajax_cache';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { InternalEvents } from '~/tracking';
import BranchDropdown from '~/search/sidebar/components/shared/branch_dropdown.vue';
import { BRANCH_REF_TYPE_ICON } from '~/ref/constants';
import {
  SEARCH_ICON,
  EVENT_SELECT_SOURCE_BRANCH_FILTER_ON_MERGE_REQUEST_PAGE,
} from '../../constants';

const trackingMixin = InternalEvents.mixin();

export const SOURCE_BRANCH_PARAM = 'source_branch';
export const NOT_SOURCE_BRANCH_PARAM = 'not[source_branch]';
export const SOURCE_BRANCH_ENDPOINT_PATH = '/-/autocomplete/merge_request_source_branches.json';

export default {
  name: 'SourceBranchFilter',
  components: {
    BranchDropdown,
    GlFormCheckbox,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [trackingMixin],
  data() {
    return {
      sourceBranches: [],
      errors: [],
      toggleState: false,
      selectedBranch: '',
      isLoading: false,
    };
  },
  i18n: {
    toggleTooltip: s__('GlobalSearch|Toggle if results have source branch included or excluded'),
  },
  computed: {
    ...mapState(['groupInitialJson', 'projectInitialJson', 'query']),
    showDropdownPlaceholderText() {
      return !this.selectedBranch ? s__('GlobalSearch|Search') : this.selectedBranch;
    },
    showDropdownPlaceholderIcon() {
      return !this.selectedBranch ? SEARCH_ICON : BRANCH_REF_TYPE_ICON;
    },
  },
  mounted() {
    this.selectedBranch =
      this.query?.[SOURCE_BRANCH_PARAM] || this.query?.[NOT_SOURCE_BRANCH_PARAM];
    this.toggleState = Boolean(this.query?.[NOT_SOURCE_BRANCH_PARAM]);
  },
  methods: {
    ...mapActions(['setQuery', 'applyQuery']),
    getMergeRequestSourceBranchesEndpoint() {
      const endpoint = `${gon.relative_url_root || ''}${SOURCE_BRANCH_ENDPOINT_PATH}`;
      const params = {
        group_id: this.groupInitialJson?.id || null,
        project_id: this.projectInitialJson?.id || null,
      };
      return mergeUrlParams(params, endpoint);
    },
    convertToListboxItems(data) {
      return data.map((item) => ({
        text: item.title,
        value: item.title,
      }));
    },
    async getCachedSourceBranches() {
      this.isLoading = true;
      try {
        const data = await AjaxCache.retrieve(this.getMergeRequestSourceBranchesEndpoint());
        this.errors = [];
        this.isLoading = false;
        this.sourceBranches = this.convertToListboxItems(data);
      } catch (e) {
        this.isLoading = false;
        this.errors.push(e.message);
      }
    },
    handleSelected(ref) {
      this.selectedBranch = ref;

      if (this.toggleState) {
        this.setQuery({ key: SOURCE_BRANCH_PARAM, value: '' });
        this.setQuery({ key: NOT_SOURCE_BRANCH_PARAM, value: ref });
        this.trackEvent(EVENT_SELECT_SOURCE_BRANCH_FILTER_ON_MERGE_REQUEST_PAGE, {
          label: 'exclude',
        });
        return;
      }

      this.setQuery({ key: SOURCE_BRANCH_PARAM, value: ref });
      this.setQuery({ key: NOT_SOURCE_BRANCH_PARAM, value: '' });
      this.trackEvent(EVENT_SELECT_SOURCE_BRANCH_FILTER_ON_MERGE_REQUEST_PAGE, {
        label: 'include',
      });
    },
    changeCheckboxInput(state) {
      this.toggleState = state;
      this.handleSelected(this.selectedBranch);
    },
    handleReset() {
      this.toggleState = false;
      this.setQuery({ key: SOURCE_BRANCH_PARAM, value: '' });
      this.setQuery({ key: NOT_SOURCE_BRANCH_PARAM, value: '' });
      this.applyQuery();
    },
  },
  SOURCE_BRANCH_PARAM,
};
</script>

<template>
  <div class="gl-relative gl-pb-0 md:gl-pt-0">
    <div class="gl-mb-2 gl-text-sm gl-font-bold" data-testid="source-branch-filter-title">
      {{ s__('GlobalSearch|Source branch') }}
    </div>
    <branch-dropdown
      :source-branches="sourceBranches"
      :errors="errors"
      :header-text="s__('GlobalSearch|Source branch')"
      :search-branch-text="showDropdownPlaceholderText"
      :selected-branch="selectedBranch"
      :icon="showDropdownPlaceholderIcon"
      :is-loading="isLoading"
      @selected="handleSelected"
      @shown="getCachedSourceBranches"
      @reset="handleReset"
    />
    <gl-form-checkbox
      v-model="toggleState"
      class="gl-inline-flex gl-w-full gl-grow gl-justify-between"
      @input="changeCheckboxInput"
    >
      <span v-gl-tooltip="$options.i18n.toggleTooltip" data-testid="branch">
        {{ s__('GlobalSearch|Branch not included') }}
      </span>
    </gl-form-checkbox>
  </div>
</template>
