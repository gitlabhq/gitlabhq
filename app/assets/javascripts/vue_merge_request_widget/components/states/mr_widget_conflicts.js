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
        status="warning"
        :show-disabled-button="true" />
      <div class="media-body space-children">
        <span
          v-if="mr.shouldBeRebased"
          class="bold">
          Fast-forward merge is not possible.
          To merge this request, first rebase locally.
        </span>
        <template v-else>
          <span class="bold">
            There are merge conflicts<span v-if="!mr.canMerge">.</span>
            <span v-if="!mr.canMerge">
              Resolve these conflicts or ask someone with write access to this repository to merge it locally
            </span>
          </span>
          <a
            v-if="mr.canMerge && mr.conflictResolutionPath"
            :href="mr.conflictResolutionPath"
            class="js-resolve-conflicts-button btn btn-default btn-xs">
            Resolve conflicts
          </a>
          <a
            v-if="mr.canMerge"
            class="js-merge-locally-button btn btn-default btn-xs"
            data-toggle="modal"
            href="#modal_merge_info">
            Merge locally
          </a>
        </template>
      </div>
    </div>
  `,
};
