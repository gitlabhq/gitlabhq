export default {
  name: 'MRWidgetLocked',
  props: {
    mr: { type: Object, required: true },
  },
  template: `
    <div class="mr-state-locked">
      <span class="state-label">Locked</span>
      This merge request is in the process of being merged, during which time it is locked and cannot be closed.
      <i
        class="fa fa-spinner fa-spin"
        aria-hidden="true" />
      <section class="mr-info-list mr-links">
        <p>
          The changes will be merged into
          <span class="label-branch">
            <a :href="mr.targetBranchPath">{{mr.targetBranch}}</a>
          </span>.
        </p>
      </section>
    </div>
  `,
};
