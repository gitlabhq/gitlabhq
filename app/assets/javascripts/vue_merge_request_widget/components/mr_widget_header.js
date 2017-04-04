require('../../lib/utils/text_utility');

export default {
  name: 'MRWidgetHeader',
  props: {
    mr: { type: Object, required: true },
  },
  computed: {
    shouldShowCommitsBehindText() {
      return this.mr.divergedCommitsCount > 0;
    },
    commitsText() {
      return gl.text.pluralize('commit', this.mr.divergedCommitsCount);
    },
  },
  methods: {
    isLongBranchTitle(branchTitle) {
      return branchTitle.length > 32;
    },
  },
  template: `
    <div class="mr-source-target">
      <div class="pull-right" v-if="mr.isOpen">
        <a href="#modal_merge_info" data-toggle="modal" class="btn inline btn-grouped btn-sm">Check out branch</a>
        <span class="dropdown inline prepend-left-5">
          <a class="btn btn-sm dropdown-toggle" data-toggle="dropdown" aria-label="Download as">
            <i class="fa fa-download" aria-hidden="true"></i>
            <i class="fa fa-caret-down" aria-hidden="true"></i>
          </a>
          <ul class="dropdown-menu dropdown-menu-align-right">
            <li>
              <a :href="mr.emailPatchesPath" download>Email patches</a>
            </li>
            <li>
              <a :href="mr.plainDiffPath" download>Plain diff</a>
            </li>
          </ul>
        </span>
      </div>
      <div class="normal">
        <b>Request to merge</b>
        <span class="label-branch"
              data-placement="bottom"
              v-bind:class="{ 'label-truncated has-tooltip': isLongBranchTitle(mr.sourceBranch) }"
              :title="isLongBranchTitle(mr.sourceBranch) ? mr.sourceBranch : null">
          <a :href="mr.sourceBranchPath">{{mr.sourceBranch}}</a>
        </span>
        <button class="btn btn-transparent btn-clipboard has-tooltip"
                data-title="Copy branch name to clipboard"
                :data-clipboard-text="mr.sourceBranch">
          <i aria-hidden="true" class="fa fa-clipboard"></i>
        </button>
        <b>into</b>
        <span class="label-branch"
              v-bind:class="{ 'label-truncated has-tooltip': isLongBranchTitle(mr.targetBranch) }"
              :title="isLongBranchTitle(mr.targetBranch) ? mr.targetBranch : null">
          <a :href="mr.targetBranchPath">{{mr.targetBranch}}</a>
        </span>
        <span
          v-if="shouldShowCommitsBehindText"
          class="diverged-commits-count">
          ({{mr.divergedCommitsCount}} {{commitsText}} behind)
        </span>
      </div>
    </div>
  `,
};
