import mrWidgetAuthorTime from '../../components/mr_widget_author_time';
import statusIcon from '../mr_widget_status_icon';

export default {
  name: 'MRWidgetClosed',
  props: {
    mr: { type: Object, required: true },
  },
  components: {
    'mr-widget-author-and-time': mrWidgetAuthorTime,
    statusIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <status-icon status="warning" />
      <div class="media-body">
        <mr-widget-author-and-time
          actionText="Closed by"
          :author="mr.metrics.closedBy"
          :dateTitle="mr.metrics.closedAt"
          :dateReadable="mr.metrics.readableClosedAt"
        />
        <section class="mr-info-list">
          <p>
            The changes were not merged into
            <a
              :href="mr.targetBranchPath"
              class="label-branch">
              {{mr.targetBranch}}</a>
          </p>
        </section>
      </div>
    </div>
  `,
};
