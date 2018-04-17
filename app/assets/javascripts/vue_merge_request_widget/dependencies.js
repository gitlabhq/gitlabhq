/**
 * This file is the centerpiece of an attempt to reduce potential conflicts
 * between the CE and EE versions of the MR widget. EE additions to the MR widget should
 * be contained in the ee/vue_merge_request_widget directory, and should **extend**
 * rather than mutate CE MR Widget code.
 *
 * This file should be the only source of conflicts between EE and CE. EE-only components should
 * imported directly where they are needed, and import paths for EE extensions of CE components
 * should overwrite import paths **without** changing the order of dependencies listed here.
 */

export { default as Vue } from 'vue';
export { default as SmartInterval } from '~/smart_interval';
export { default as WidgetHeader } from './components/mr_widget_header.vue';
export { default as WidgetMergeHelp } from './components/mr_widget_merge_help.vue';
export { default as WidgetPipeline } from './components/mr_widget_pipeline.vue';
export { default as Deployment } from './components/deployment.vue';
export { default as WidgetMaintainerEdit } from './components/mr_widget_maintainer_edit.vue';
export { default as WidgetRelatedLinks } from './components/mr_widget_related_links.vue';
export { default as MergedState } from './components/states/mr_widget_merged.vue';
export { default as FailedToMerge } from './components/states/mr_widget_failed_to_merge.vue';
export { default as ClosedState } from './components/states/mr_widget_closed.vue';
export { default as MergingState } from './components/states/mr_widget_merging.vue';
export { default as WipState } from './components/states/mr_widget_wip';
export { default as ArchivedState } from './components/states/mr_widget_archived.vue';
export { default as ConflictsState } from './components/states/mr_widget_conflicts.vue';
export { default as NothingToMergeState } from './components/states/nothing_to_merge.vue';
export { default as MissingBranchState } from './components/states/mr_widget_missing_branch.vue';
export { default as NotAllowedState } from './components/states/mr_widget_not_allowed.vue';
<<<<<<< HEAD
export { default as ReadyToMergeState } from 'ee/vue_merge_request_widget/components/states/mr_widget_ready_to_merge';
=======
export { default as ReadyToMergeState } from './components/states/ready_to_merge.vue';
>>>>>>> upstream/master
export { default as ShaMismatchState } from './components/states/sha_mismatch.vue';
export { default as UnresolvedDiscussionsState } from './components/states/unresolved_discussions.vue';
export { default as PipelineBlockedState } from './components/states/mr_widget_pipeline_blocked.vue';
export { default as PipelineFailedState } from './components/states/mr_widget_pipeline_failed';
export { default as MergeWhenPipelineSucceedsState } from './components/states/mr_widget_merge_when_pipeline_succeeds.vue';
export { default as RebaseState } from './components/states/mr_widget_rebase.vue';
export { default as AutoMergeFailed } from './components/states/mr_widget_auto_merge_failed.vue';
export { default as CheckingState } from './components/states/mr_widget_checking.vue';
export { default as MRWidgetStore } from 'ee/vue_merge_request_widget/stores/mr_widget_store';
export { default as MRWidgetService } from 'ee/vue_merge_request_widget/services/mr_widget_service';
export { default as eventHub } from './event_hub';
export { default as getStateKey } from 'ee/vue_merge_request_widget/stores/get_state_key';
export { default as stateMaps } from 'ee/vue_merge_request_widget/stores/state_maps';
export { default as SquashBeforeMerge } from 'ee/vue_merge_request_widget/components/states/mr_widget_squash_before_merge';
export { default as notify } from '../lib/utils/notify';
export { default as SourceBranchRemovalStatus } from './components/source_branch_removal_status.vue';

export { default as mrWidgetOptions } from 'ee/vue_merge_request_widget/mr_widget_options';
