export default {
  props: [
    'pipeline',
  ],
  computed: {
    user() {
      return !!this.pipeline.user;
    },
  },
  template: `
    <td>
      <a
        :href="pipeline.path"
        class="js-pipeline-url-link">
        <span class="pipeline-id">#{{pipeline.id}}</span>
      </a>
      <span>by</span>
      <a
        class="js-pipeline-url-user"
        v-if="user"
        :href="pipeline.user.web_url">
        <img
          v-if="user"
          class="avatar has-tooltip s20 "
          :title="pipeline.user.name"
          data-container="body"
          :src="pipeline.user.avatar_url"
        >
      </a>
      <span
        v-if="!user"
        class="js-pipeline-url-api api monospace">
        API
      </span>
      <span
        v-if="pipeline.flags.latest"
        class="js-pipeline-url-lastest label label-success has-tooltip"
        title="Latest pipeline for this branch"
        data-original-title="Latest pipeline for this branch">
        latest
      </span>
      <span
        v-if="pipeline.flags.yaml_errors"
        class="js-pipeline-url-yaml label label-danger has-tooltip"
        :title="pipeline.yaml_errors"
        :data-original-title="pipeline.yaml_errors">
        yaml invalid
      </span>
      <span
        v-if="pipeline.flags.stuck"
        class="js-pipeline-url-stuck label label-warning">
        stuck
      </span>
    </td>
  `,
};
