import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';

export default {
  props: [
    'pipeline',
  ],
  computed: {
    user() {
      return !!this.pipeline.user;
    },
  },
  components: {
    userAvatarLink,
  },
  template: `
    <td>
      <a
        :href="pipeline.path"
        class="js-pipeline-url-link">
        <span class="pipeline-id">#{{pipeline.id}}</span>
      </a>
      <span>by</span>
      <user-avatar-link
        v-if="user"
        class="js-pipeline-url-user"
        :link-href="pipeline.user.web_url"
        :img-src="pipeline.user.avatar_url"
        :tooltip-text="pipeline.user.name"
      />
      <span
        v-if="!user"
        class="js-pipeline-url-api api">
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
