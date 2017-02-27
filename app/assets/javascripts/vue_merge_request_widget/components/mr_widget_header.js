export default {
  name: 'MRWidgetHeader',
  props: {
    targetBranch: { type: String, default: '', required: true },
    sourceBranch: { type: String, default: '', required: true },
  },
  template: `
    <div class="normal">
      <span>Request to merge</span>
      <span class="label-branch">{{this.sourceBranch}}</span>
      <span>into</span>
      <span class="label-branch">
        <a href="#">{{this.targetBranch}}</a>
      </span>
    </div>
  `,
};
