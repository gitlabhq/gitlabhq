<script>
import {
  GlFormGroup,
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
  GlSkeletonLoader,
  GlSearchBoxByType,
  GlDropdownText,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { debounce } from 'lodash';
import Tracking from '~/tracking';
import { s__, __ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { MILESTONE_STATE } from '~/sidebar/constants';
import projectMilestonesQuery from '~/sidebar/queries/project_milestones.query.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import {
  I18N_WORK_ITEM_ERROR_UPDATING,
  sprintfWorkItem,
  TRACKING_CATEGORY_SHOW,
} from '../constants';

const noMilestoneId = 'no-milestone-id';

export default {
  i18n: {
    MILESTONE: s__('WorkItem|Milestone'),
    NONE: s__('WorkItem|None'),
    MILESTONE_PLACEHOLDER: s__('WorkItem|Add to milestone'),
    NO_MATCHING_RESULTS: s__('WorkItem|No matching results'),
    NO_MILESTONE: s__('WorkItem|No milestone'),
    MILESTONE_FETCH_ERROR: s__(
      'WorkItem|Something went wrong while fetching milestones. Please try again.',
    ),
    EXPIRED_TEXT: __('(expired)'),
  },
  components: {
    GlFormGroup,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlSkeletonLoader,
    GlSearchBoxByType,
    GlDropdownText,
  },
  mixins: [Tracking.mixin()],
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    workItemMilestone: {
      type: Object,
      required: false,
      default: () => {},
    },
    workItemType: {
      type: String,
      required: false,
      default: '',
    },
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    fullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      localMilestone: this.workItemMilestone,
      searchTerm: '',
      shouldFetch: false,
      updateInProgress: false,
      isFocused: false,
      milestones: [],
    };
  },
  computed: {
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_milestone',
        property: `type_${this.workItemType}`,
      };
    },
    emptyPlaceholder() {
      return this.canUpdate ? this.$options.i18n.MILESTONE_PLACEHOLDER : this.$options.i18n.NONE;
    },
    expired() {
      return this.localMilestone?.expired ? ` ${this.$options.i18n.EXPIRED_TEXT}` : '';
    },
    dropdownText() {
      return this.localMilestone?.title
        ? `${this.localMilestone?.title}${this.expired}`
        : this.emptyPlaceholder;
    },
    isLoadingMilestones() {
      return this.$apollo.queries.milestones.loading;
    },
    isNoMilestone() {
      return this.localMilestone?.id === noMilestoneId || !this.localMilestone?.id;
    },
    dropdownClasses() {
      return {
        'gl-text-gray-500!': this.canUpdate && this.isNoMilestone,
        'is-not-focused': !this.isFocused,
        'gl-min-w-20': true,
      };
    },
  },
  watch: {
    workItemMilestone: {
      handler(newVal) {
        this.localMilestone = newVal;
      },
      deep: true,
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  apollo: {
    milestones: {
      query: projectMilestonesQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          title: this.searchTerm,
          state: MILESTONE_STATE.ACTIVE,
          first: 20,
        };
      },
      skip() {
        return !this.shouldFetch;
      },
      update(data) {
        return data?.workspace?.attributes?.nodes || [];
      },
      error() {
        this.$emit('error', this.i18n.MILESTONE_FETCH_ERROR);
      },
    },
  },
  methods: {
    handleMilestoneClick(milestone) {
      this.localMilestone = milestone;
    },
    onDropdownShown() {
      this.$refs.search.focusInput();
      this.shouldFetch = true;
      this.isFocused = true;
    },
    onDropdownHide() {
      this.isFocused = false;
      this.searchTerm = '';
      this.shouldFetch = false;
      this.updateMilestone();
    },
    setSearchKey(value) {
      this.searchTerm = value;
    },
    isMilestoneChecked(milestone) {
      return this.localMilestone?.id === milestone?.id;
    },
    updateMilestone() {
      if (this.workItemMilestone?.id === this.localMilestone?.id) {
        return;
      }

      this.track('updated_milestone');
      this.updateInProgress = true;
      this.$apollo
        .mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              milestoneWidget: {
                milestoneId:
                  this.localMilestone?.id === 'no-milestone-id' ? null : this.localMilestone?.id,
              },
            },
          },
        })
        .then(({ data }) => {
          if (data.workItemUpdate.errors.length) {
            throw new Error(data.workItemUpdate.errors.join('\n'));
          }
        })
        .catch((error) => {
          const msg = sprintfWorkItem(I18N_WORK_ITEM_ERROR_UPDATING, this.workItemType);
          this.$emit('error', msg);
          Sentry.captureException(error);
        })
        .finally(() => {
          this.updateInProgress = false;
        });
    },
  },
};
</script>

<template>
  <gl-form-group
    class="work-item-dropdown gl-flex-nowrap"
    :label="$options.i18n.MILESTONE"
    label-for="milestone-value"
    label-class="gl-pb-0! gl-mt-3 gl-overflow-wrap-break"
    label-cols="3"
    label-cols-lg="2"
  >
    <span
      v-if="!canUpdate"
      class="gl-text-secondary gl-ml-4 gl-mt-3 gl-display-inline-block gl-line-height-normal"
      data-testid="disabled-text"
    >
      {{ dropdownText }}
    </span>
    <gl-dropdown
      v-else
      id="milestone-value"
      data-testid="work-item-milestone-dropdown"
      class="gl-pl-0 gl-max-w-full"
      :toggle-class="dropdownClasses"
      :text="dropdownText"
      :loading="updateInProgress"
      @shown="onDropdownShown"
      @hide="onDropdownHide"
    >
      <template #header>
        <gl-search-box-by-type ref="search" :value="searchTerm" @input="debouncedSearchKeyUpdate" />
      </template>
      <gl-dropdown-item
        data-testid="no-milestone"
        is-check-item
        :is-checked="isNoMilestone"
        @click="handleMilestoneClick({ id: 'no-milestone-id' })"
      >
        {{ $options.i18n.NO_MILESTONE }}
      </gl-dropdown-item>
      <gl-dropdown-divider />
      <gl-dropdown-text v-if="isLoadingMilestones">
        <gl-skeleton-loader :height="90">
          <rect width="380" height="10" x="10" y="15" rx="4" />
          <rect width="280" height="10" x="10" y="30" rx="4" />
          <rect width="380" height="10" x="10" y="50" rx="4" />
          <rect width="280" height="10" x="10" y="65" rx="4" />
        </gl-skeleton-loader>
      </gl-dropdown-text>
      <template v-else-if="milestones.length">
        <gl-dropdown-item
          v-for="milestone in milestones"
          :key="milestone.id"
          is-check-item
          :is-checked="isMilestoneChecked(milestone)"
          @click="handleMilestoneClick(milestone)"
        >
          {{ milestone.title }}
          <template v-if="milestone.expired">{{ $options.i18n.EXPIRED_TEXT }}</template>
        </gl-dropdown-item>
      </template>
      <gl-dropdown-text v-else>{{ $options.i18n.NO_MATCHING_RESULTS }}</gl-dropdown-text>
    </gl-dropdown>
  </gl-form-group>
</template>
