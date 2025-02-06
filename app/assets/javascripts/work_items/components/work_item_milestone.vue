<script>
import { GlLink } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import Tracking from '~/tracking';
import { newWorkItemId } from '~/work_items/utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__, __ } from '~/locale';
import { MILESTONE_STATE } from '~/sidebar/constants';
import WorkItemSidebarDropdownWidget from '~/work_items/components/shared/work_item_sidebar_dropdown_widget.vue';
import projectMilestonesQuery from '~/sidebar/queries/project_milestones.query.graphql';
import groupMilestonesQuery from '~/sidebar/queries/group_milestones.query.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import updateNewWorkItemMutation from '~/work_items/graphql/update_new_work_item.mutation.graphql';
import {
  I18N_WORK_ITEM_ERROR_UPDATING,
  sprintfWorkItem,
  TRACKING_CATEGORY_SHOW,
} from '../constants';

export default {
  i18n: {
    milestone: s__('WorkItem|Milestone'),
    none: s__('WorkItem|None'),
    noMilestone: s__('WorkItem|No milestone'),
    milestoneFetchError: s__(
      'WorkItem|Something went wrong while fetching milestones. Please try again.',
    ),
    expiredText: __('(expired)'),
  },
  components: {
    WorkItemSidebarDropdownWidget,
    GlLink,
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
    isGroup: {
      type: Boolean,
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
      searchTerm: '',
      shouldFetch: false,
      updateInProgress: false,
      milestones: [],
      localMilestone: this.workItemMilestone,
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
      return this.canUpdate ? this.$options.i18n.noMilestone : this.$options.i18n.none;
    },
    expired() {
      return this.localMilestone?.expired ? ` ${this.$options.i18n.expiredText}` : '';
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
      return this.milestones.map(({ id, title, expired }) => ({
        value: id,
        text: title,
        expired,
      }));
    },
    localMilestoneId() {
      return this.localMilestone?.id;
    },
    localMilestoneNumericId() {
      return this.localMilestoneId ? getIdFromGraphQLId(this.localMilestoneId) : '';
    },
  },
  watch: {
    workItemMilestone(newVal) {
      this.localMilestone = newVal;
      this.selectedMilestoneId = newVal?.id;
    },
  },
  apollo: {
    milestones: {
      query() {
        return this.isGroup ? groupMilestonesQuery : projectMilestonesQuery;
      },
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
        this.$emit('error', this.i18n.milestoneFetchError);
      },
    },
  },
  methods: {
    onDropdownShown() {
      this.searchTerm = '';
      this.shouldFetch = true;
    },
    search(searchTerm) {
      this.searchTerm = searchTerm;
      this.shouldFetch = true;
    },
    itemExpiredText(item) {
      return item.expired ? ` ${this.$options.i18n.expiredText}` : '';
    },
    updateMilestone(selectedMilestoneId) {
      if (this.localMilestone?.id === selectedMilestoneId) {
        return;
      }

      this.localMilestone = selectedMilestoneId
        ? this.milestones.find(({ id }) => id === selectedMilestoneId)
        : null;

      this.track('updated_milestone');
      this.updateInProgress = true;

      if (this.workItemId === newWorkItemId(this.workItemType)) {
        this.$apollo
          .mutate({
            mutation: updateNewWorkItemMutation,
            variables: {
              input: {
                fullPath: this.fullPath,
                milestone: this.localMilestone
                  ? {
                      ...this.localMilestone,
                      webPath: this.localMilestone.webUrl,
                      startDate: '',
                    }
                  : null,
                workItemType: this.workItemType,
              },
            },
          })
          .catch((error) => {
            Sentry.captureException(error);
          })
          .finally(() => {
            this.updateInProgress = false;
            this.searchTerm = '';
            this.shouldFetch = false;
          });
        return;
      }

      this.$apollo
        .mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              milestoneWidget: {
                milestoneId: selectedMilestoneId,
              },
            },
          },
        })
        .then(({ data }) => {
          if (data.workItemUpdate.errors.length) {
            throw new Error(data.workItemUpdate.errors.join('\n'));
          }
          this.$emit('milestoneUpdated', selectedMilestoneId);
        })
        .catch((error) => {
          this.localMilestone = this.workItemMilestone;
          const msg = sprintfWorkItem(I18N_WORK_ITEM_ERROR_UPDATING, this.workItemType);
          this.$emit('error', msg);
          Sentry.captureException(error);
        })
        .finally(() => {
          this.updateInProgress = false;
          this.searchTerm = '';
          this.shouldFetch = false;
        });
    },
  },
};
</script>

<template>
  <work-item-sidebar-dropdown-widget
    :dropdown-label="$options.i18n.milestone"
    :can-update="canUpdate"
    dropdown-name="milestone"
    :loading="isLoadingMilestones"
    :list-items="milestonesList"
    :item-value="localMilestoneId"
    :update-in-progress="updateInProgress"
    :toggle-dropdown-text="dropdownText"
    :header-text="__('Select milestone')"
    :reset-button-label="__('Clear')"
    data-testid="work-item-milestone"
    @dropdownShown="onDropdownShown"
    @searchStarted="search"
    @updateValue="updateMilestone"
  >
    <template #list-item="{ item }">
      <div>{{ item.text }}{{ itemExpiredText(item) }}</div>
      <div v-if="item.title">{{ item.title }}</div>
    </template>
    <template #readonly>
      <gl-link
        class="has-popover !gl-text-default"
        :data-milestone="localMilestoneNumericId"
        data-reference-type="milestone"
        data-placement="left"
        :href="localMilestone.webPath"
      >
        {{ localMilestone.title }}{{ expired }}
      </gl-link>
    </template>
  </work-item-sidebar-dropdown-widget>
</template>
