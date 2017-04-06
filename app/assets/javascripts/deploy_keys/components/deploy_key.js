export default {
  name: 'DeployKey',
  props: {
    title: {
      type: String,
      required: true,
    },
    fingerprint: {
      type: String,
      required: true,
    },
    projects: {
      type: Array,
      required: false,
      default: [],
    },
    canPush: {
      type: Boolean,
      required: false,
      default: false,
    },
    createdAt: {
      type: String,
      required: true,
    },
  },
  computed: {
    timeagoDate() {
      return gl.utils.getTimeago().format(this.createdAt, 'gl_en')
    },
  },
  template: `
    <li>
      <div class="pull-left append-right-10 hidden-xs">
        <i class="fa fa-key fa-key-icon" aria-hidden="true" />
      </div>
      <div class="deploy-key-content key-list-item-info">
        <strong class="title">{{title}}</strong>
        <div class="description">
          {{fingerprint}}
          <div v-if="canPush" class="write-access-allowed">
            Write access allowed
          </div>
        </div>
      </div>
      <div class="deploy-key-content prepend-left-default deploy-key-projects">
        <a v-for="project in projects"
          class="label deploy-project-label"
          :href="project.full_path"
        >
          {{project.name}}
        </a>
      </div>
      <div class="deploy-key-content">
        <span class="key-created-at">
          created
          <span
            class="js-created-at-timeago"
            data-toggle="tooltip"
            data-placement="top"
            :datetime="createdAt"
          >
            {{ timeagoDate }}
          </span>
        </span>
        <div class="visible-xs-block visible-sm-block" />
        <a
          class="btn btn-sm prepend-left-10"
          rel="nofollow"
          data-method="put"
          href="#"
        >
          Enable
        </a>
      </div>
    </li>
  `,
};