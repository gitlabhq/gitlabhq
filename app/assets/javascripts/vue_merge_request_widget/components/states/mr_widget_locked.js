module.exports = {
  name: 'MRWidgetLocked',
  props: {
    targetBranch: { type: Object, required: true, default: () => ({}) }
  },
  template: `
    <div class="mr-widget-body">
      <span class="bold">Locked</span> This merge request is in the process of being merged, during which time it is locked and cannot be closed
      <i class="fa fa-spinner fa-spin"></i>
      <section>
        <p>The changes will be merged into
          <a :href="targetBranchPath" class="label-branch">
            {{targetBranch}}
          </a>
        </p>
      </section>
    </div>
  `
};
