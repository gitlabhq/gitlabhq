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
  template: `
    <div class="mr-source-target">
      <div class="pull-right" v-if="mr.isOpen">
        <a href="#modal_merge_info" data-toggle="modal" class="btn inline btn-grouped btn-sm">Check out branch</a>
        <span class="dropdown inline prepend-left-5">
          <a class="btn btn-sm dropdown-toggle" data-toggle="dropdown">
            Download as <i class="fa fa-caret-down" aria-hidden="true"></i>
          </a>
          <ul class="dropdown-menu dropdown-menu-align-right">
            <li>
              <a :href="mr.emailPatchesPath">Email patches</a>
            </li>
            <li>
              <a :href="mr.plainDiffPath">Plain diff</a>
            </li>
          </ul>
        </span>
      </div>
      <div class="normal">
        <span>Request to merge</span>
        <span class="label-branch">{{mr.sourceBranch}}</span>
        <span>into</span>
        <span class="label-branch">
          <a href="#">{{mr.targetBranch}}</a>
        </span>
        <span v-if="shouldShowCommitsBehindText">({{mr.divergedCommitsCount}} {{commitsText}} behind)</span>
      </div>
    </div>
  `,
};
