import '../../lib/utils/text_utility';

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
    isBranchTitleLong(branchTitle) {
      return branchTitle.length > 32;
    },
  },
  template: `
    <div class="mr-source-target">
      <div
        v-if="mr.isOpen"
        class="pull-right">
        <a
          href="#modal_merge_info"
          data-toggle="modal"
          class="btn inline btn-grouped btn-sm">
          Check out branch
        </a>
        <span class="dropdown inline prepend-left-5">
          <a
            class="btn btn-sm dropdown-toggle"
            data-toggle="dropdown"
            aria-label="Download as"
            role="button">
            <i
              class="fa fa-download"
              aria-hidden="true" />
            <i
              class="fa fa-caret-down"
              aria-hidden="true" />
          </a>
          <ul class="dropdown-menu dropdown-menu-align-right">
            <li>
              <a
                :href="mr.emailPatchesPath"
                download>
                Email patches
              </a>
            </li>
            <li>
              <a
                :href="mr.plainDiffPath"
                download>
                Plain diff
              </a>
            </li>
          </ul>
        </span>
      </div>
      <div class="normal">
        <b>Request to merge</b>
        <span
          class="label-branch"
          :class="{'label-truncated has-tooltip': isBranchTitleLong(mr.sourceBranch)}"
          :title="isBranchTitleLong(mr.sourceBranch) ? mr.sourceBranch : ''"
          data-placement="bottom"
          v-html="mr.sourceBranchLink"></span>
        <button
          class="btn btn-transparent btn-clipboard has-tooltip"
          data-title="Copy branch name to clipboard"
          :data-clipboard-text="mr.sourceBranch">
          <i
            aria-hidden="true"
            class="fa fa-clipboard"></i>
        </button>
        <b>into</b>
        <span
          class="label-branch"
          :class="{'label-truncated has-tooltip': isBranchTitleLong(mr.targetBranch)}"
          :title="isBranchTitleLong(mr.targetBranch) ? mr.targetBranch : ''"
          data-placement="bottom">
          <a :href="mr.targetBranchCommitsPath">{{mr.targetBranch}}</a>
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
