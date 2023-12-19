<script>
import { GlCollapsibleListbox, GlFormGroup, GlSkeletonLoader } from '@gitlab/ui';
import { debounce } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
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

export const noMilestoneId = 'no-milestone-id';
const noMilestoneItem = { text: s__('WorkItem|No milestone'), value: noMilestoneId };

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
    GlCollapsibleListbox,
    GlFormGroup,
    GlSkeletonLoader,
  },
  mixins: [Tracking.mixin()],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemId: {
      type: String,
      required: true,
    },
    workItemMilestone: {
      type: Object,
      required: false,
      default: () => ({}),
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
  },
  data() {
    return {
      localMilestone: this.workItemMilestone,
      localMilestoneId: this.workItemMilestone?.id,
      searchTerm: '',
      shouldFetch: false,
      updateInProgress: false,
      milestones: [],
      dropdownGroups: [
        {
          text: this.$options.i18n.NO_MILESTONE,
          textSrOnly: true,
          options: [noMilestoneItem],
        },
        {
          text: __('Milestones'),
          textSrOnly: true,
          options: [],
        },
      ],
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
    milestonesList() {
      return (
        this.milestones.map(({ id, title, expired }) => {
          return {
            value: id,
            text: title,
            expired,
          };
        }) ?? []
      );
    },
    toggleClasses() {
      const toggleClasses = ['gl-max-w-full'];

      if (this.localMilestoneId === noMilestoneId) {
        toggleClasses.push('gl-text-gray-500!');
      }
      return toggleClasses;
    },
  },
  watch: {
    milestones() {
      this.dropdownGroups[1].options = this.milestonesList;
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
    onDropdownShown() {
      this.shouldFetch = true;
    },
    onDropdownHide() {
      this.searchTerm = '';
      this.shouldFetch = false;
    },
    setSearchKey(value) {
      this.searchTerm = value;
    },
    updateMilestone() {
      this.localMilestone =
        this.milestones.find(({ id }) => id === this.localMilestoneId) ?? noMilestoneItem;

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
                milestoneId: this.localMilestoneId === noMilestoneId ? null : this.localMilestoneId,
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
    label-class="gl-pb-0! gl-mt-3 gl-overflow-wrap-break work-item-field-label"
    label-cols="3"
    label-cols-lg="2"
  >
    <span
      v-if="!canUpdate"
      class="gl-text-secondary gl-ml-4 gl-mt-3 gl-display-inline-block gl-line-height-normal work-item-field-value"
      data-testid="disabled-text"
    >
      {{ dropdownText }}
    </span>

    <gl-collapsible-listbox
      v-else
      id="milestone-value"
      v-model="localMilestoneId"
      :items="dropdownGroups"
      category="tertiary"
      class="gl-max-w-full"
      :toggle-text="dropdownText"
      :loading="updateInProgress"
      :toggle-class="toggleClasses"
      searchable
      @select="updateMilestone"
      @shown="onDropdownShown"
      @hidden="onDropdownHide"
      @search="debouncedSearchKeyUpdate"
    >
      <template #list-item="{ item }">
        {{ item.text }}
        <span v-if="item.expired">{{ $options.i18n.EXPIRED_TEXT }}</span>
      </template>
      <template #footer>
        <gl-skeleton-loader v-if="isLoadingMilestones" :height="90">
          <rect width="380" height="10" x="10" y="15" rx="4" />
          <rect width="280" height="10" x="10" y="30" rx="4" />
          <rect width="380" height="10" x="10" y="50" rx="4" />
          <rect width="280" height="10" x="10" y="65" rx="4" />
        </gl-skeleton-loader>

        <div
          v-else-if="!milestones.length"
          aria-live="assertive"
          class="gl-pl-7 gl-pr-5 gl-py-3 gl-font-base gl-text-gray-600"
          data-testid="no-results-text"
        >
          {{ $options.i18n.NO_MATCHING_RESULTS }}
        </div>
      </template>
    </gl-collapsible-listbox>
  </gl-form-group>
</template>
