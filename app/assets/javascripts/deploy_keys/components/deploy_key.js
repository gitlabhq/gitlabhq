export default {
  name: 'DeployKey',
  props: {
    id: {
      type: Number,
      required: true,
    },
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
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
    canPush: {
      type: Boolean,
      required: false,
      default: false,
    },
    enable: {
      type: Boolean,
      required: false,
      default: true,
    },
    canRemove: {
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
    timeagoTitle() {
      return gl.utils.formatDate(new Date(this.createdAt));
    },
    linkText() {
      if (this.enable) {
        return 'Enable';
      } else if (this.canRemove) {
        return 'Remove';
      }

      return 'Disable';
    },
    confirmationMessage() {
      if (!this.enable && this.canRemove) {
        return 'You are going to remove deploy key. Are you sure?';
      }

      return '';
    },
    href() {
      const path = `/${this.path}/deploy_keys/${this.id}`;

      return this.enable ? `${path}/enable` : `${path}/disable`;
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
        <a
          v-for="project in projects"
          class="label deploy-project-label"
          :href="project.full_path"
        >
          {{project.full_name}}
        </a>
      </div>
      <div class="deploy-key-content">
        <span class="key-created-at">
          created
          <span
            data-toggle="tooltip"
            data-placement="top"
            :data-original-title="timeagoTitle"
            :datetime="createdAt"
          >
            {{ timeagoDate }}
          </span>
        </span>
        <div class="visible-xs-block visible-sm-block" />
        <a
          class="btn btn-sm prepend-left-10"
          :class="{'btn-warning': !enable}"
          data-method="put"
          :data-confirm="confirmationMessage"
          :href="href"
        >
          {{linkText}}
        </a>
      </div>
    </li>
  `,
};
