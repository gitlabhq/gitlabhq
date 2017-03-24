export default {
  name: 'MRWidgetLocked',
  props: {
    mr: { type: Object, required: true },
  },
  template: `
    <div class="mr-widget-body">
      <span class="bold">Locked</span> This merge request is in the process of being merged, during which time it is locked and cannot be closed.
      <i class="fa fa-spinner fa-spin" aria-hidden="true"></i>
      <section>
        <p>The changes will be merged into
          <a :href="mr.targetBranchPath" class="label-branch">
            {{mr.targetBranch}}
          </a>
        </p>
      </section>
    </div>
  `,
};
