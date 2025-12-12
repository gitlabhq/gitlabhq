<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { GlFormCheckbox, GlTooltipDirective } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import AjaxCache from '~/lib/utils/ajax_cache';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { InternalEvents } from '~/tracking';
import FilterDropdown from '~/search/sidebar/components/shared/filter_dropdown.vue';
// eslint-disable-next-line no-restricted-imports
import {
  EVENT_SELECT_TARGET_BRANCH_FILTER_ON_MERGE_REQUEST_PAGE,
  TARGET_BRANCH_PARAM,
  NOT_TARGET_BRANCH_PARAM,
  TARGET_BRANCH_ENDPOINT_PATH,
} from '../../constants';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'TargetBranchFilter',
  components: {
    FilterDropdown,
    GlFormCheckbox,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [trackingMixin],
  data() {
    return {
      targetBranches: [],
      error: '',
      toggleState: false,
      selectedBranch: '',
      isLoading: false,
    };
  },
  i18n: {
    toggleTooltip: s__('GlobalSearch|Toggle if results have target branch included or excluded'),
  },
  computed: {
    ...mapState(['groupInitialJson', 'projectInitialJson', 'query']),
    showDropdownPlaceholderText() {
      return !this.selectedBranch ? s__('GlobalSearch|Search') : this.selectedBranch;
    },
  },
  mounted() {
    const targetBranch = this.query?.[TARGET_BRANCH_PARAM];
    const notTargetBranch = this.query?.[NOT_TARGET_BRANCH_PARAM];

    this.selectedBranch = targetBranch || notTargetBranch;
    this.toggleState = Boolean(notTargetBranch);
  },
  methods: {
    ...mapActions(['setQuery', 'applyQuery']),
    getMergeRequestTargetBranchesEndpoint() {
      const endpoint = `${gon.relative_url_root || ''}${TARGET_BRANCH_ENDPOINT_PATH}`;
      const params = this.projectInitialJson?.id
        ? { project_id: this.projectInitialJson.id }
        : { group_id: this.groupInitialJson?.id };

      return mergeUrlParams(params, endpoint);
    },
    convertToListboxItems(data) {
      return data.map((item) => ({
        text: item.title,
        value: item.title,
      }));
    },
    async getCachedTargetBranches() {
      this.isLoading = true;
      try {
        const data = await AjaxCache.retrieve(this.getMergeRequestTargetBranchesEndpoint());
        this.error = '';
        this.isLoading = false;
        this.targetBranches = this.convertToListboxItems(data);
      } catch (error) {
        Sentry.captureException(error);
        this.isLoading = false;
        this.error = error.message;
      }
    },
    handleSelected(ref) {
      this.selectedBranch = ref;

      if (this.toggleState) {
        this.setQuery({ key: TARGET_BRANCH_PARAM, value: '' });
        this.setQuery({ key: NOT_TARGET_BRANCH_PARAM, value: ref || '' });
        this.trackEvent(EVENT_SELECT_TARGET_BRANCH_FILTER_ON_MERGE_REQUEST_PAGE, {
          label: 'exclude',
        });
        return;
      }

      this.setQuery({ key: TARGET_BRANCH_PARAM, value: ref || '' });
      this.setQuery({ key: NOT_TARGET_BRANCH_PARAM, value: '' });
      this.trackEvent(EVENT_SELECT_TARGET_BRANCH_FILTER_ON_MERGE_REQUEST_PAGE, {
        label: 'include',
      });
    },
    changeCheckboxInput(state) {
      this.toggleState = state;
      this.handleSelected(this.selectedBranch);
    },
    handleReset() {
      this.toggleState = false;
      this.setQuery({ key: TARGET_BRANCH_PARAM, value: '' });
      this.setQuery({ key: NOT_TARGET_BRANCH_PARAM, value: '' });
      this.applyQuery();
    },
  },
  TARGET_BRANCH_PARAM,
};
</script>

<template>
  <div class="gl-relative gl-pb-0 @md/panel:gl-pt-0">
    <div class="gl-mb-2 gl-text-sm gl-font-bold" data-testid="target-branch-filter-title">
      {{ s__('GlobalSearch|Target branch') }}
    </div>
    <filter-dropdown
      :list-data="targetBranches"
      :error="error"
      :header-text="s__('GlobalSearch|Target branch')"
      :search-text="showDropdownPlaceholderText"
      :selected-item="selectedBranch"
      :is-loading="isLoading"
      @selected="handleSelected"
      @shown="getCachedTargetBranches"
      @reset="handleReset"
    />
    <gl-form-checkbox
      v-model="toggleState"
      class="gl-inline-flex gl-w-full gl-grow gl-justify-between gl-pt-4"
      @input="changeCheckboxInput"
    >
      <span v-gl-tooltip="$options.i18n.toggleTooltip" data-testid="branch">
        {{ s__('GlobalSearch|Branch not included') }}
      </span>
    </gl-form-checkbox>
  </div>
</template>
