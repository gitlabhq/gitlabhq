import mrWidgetAuthorTime from '../../components/mr_widget_author_time';

export default {
  name: 'MRWidgetClosed',
  props: {
    mr: { type: Object, required: true },
  },
  components: {
    'mr-widget-author-and-time': mrWidgetAuthorTime,
  },
  template: `
    <div class="mr-widget-body">
      <mr-widget-author-and-time
        actionText="Closed by"
        :author="mr.closedBy"
        :dateTitle="mr.updatedAt"
        :dateReadable="mr.closedAt"
      />
      <section>
        <p>
          The changes were not merged into
          <a
            :href="mr.targetBranchCommitsPath"
            class="label-branch">
            {{mr.targetBranch}}</a>.
        </p>
      </section>
    </div>
  `,
};
