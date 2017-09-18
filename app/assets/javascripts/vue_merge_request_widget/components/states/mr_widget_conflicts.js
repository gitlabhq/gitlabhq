import statusIcon from '../mr_widget_status_icon';

export default {
  name: 'MRWidgetConflicts',
  props: {
    mr: { type: Object, required: true },
  },
  components: {
    statusIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <status-icon
        ref="statusIcon"
        status="failed"
        showDisabledButton />
      <div class="media-body space-children">
        <template v-if="mr.ffOnlyEnabled">
          <span class="bold">
            Fast-forward merge is not possible.
            To merge this request, first rebase locally
          </span>
        </template>
        <template v-else>
          <span class="bold">
            There are merge conflicts<span v-if="!mr.canMerge">.</span>
            <span v-if="!mr.canMerge">
              Resolve these conflicts or ask someone with write access to this repository to merge it locally
            </span>
          </span>
          <a
            v-if="mr.canMerge && mr.conflictResolutionPath"
            ref="resolveConflictsButton"
            :href="mr.conflictResolutionPath"
            class="btn btn-default btn-xs">
            Resolve conflicts
          </a>
          <a
            v-if="mr.canMerge"
            ref="mergeLocallyButton"
            class="btn btn-default btn-xs"
            data-toggle="modal"
            href="#modal_merge_info">
            Merge locally
          </a>
        </template>
      </div>
    </div>
  `,
};
