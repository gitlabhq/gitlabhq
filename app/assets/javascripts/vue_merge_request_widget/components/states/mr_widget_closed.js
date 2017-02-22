module.exports = {
  name: 'MRWidgetClosed',
  props: {
    mr: { type: Object, required: true, default: () => ({}) }
  },
  template: `
    <div class="mr-widget-body">
      <h4>
        Closed by
        <a class="author_link" :href="mr.closedBy.webUrl">
          <img :src="mr.closedBy.avatarUrl" width="16" class="avatar avatar-inline s16" />
          <span class="author">{{mr.closedBy.name}}</span>
        </a>
        <time :data-original-title='mr.updatedAt' data-toggle="tooltip" data-placement="top" data-container="body">
          {{mr.closedAt}}
        </time>
      </h4>
      <section>
        <p>The changes were not merged into
          <a :href="mr.targetBranchPath" class="label-branch">
            {{mr.targetBranch}}
          </a>
        </p>
      </section>
    </div>
  `
};
