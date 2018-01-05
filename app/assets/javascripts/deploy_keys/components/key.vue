<script>
  import actionBtn from './action_btn.vue';
  import { getTimeago } from '../../lib/utils/datetime_utility';

  export default {
    components: {
      actionBtn,
    },
    props: {
      deployKey: {
        type: Object,
        required: true,
      },
      store: {
        type: Object,
        required: true,
      },
      endpoint: {
        type: String,
        required: true,
      },
    },
    computed: {
      timeagoDate() {
        return getTimeago().format(this.deployKey.created_at);
      },
      editDeployKeyPath() {
        return `${this.endpoint}/${this.deployKey.id}/edit`;
      },
    },
    methods: {
      isEnabled(id) {
        return this.store.findEnabledKey(id) !== undefined;
      },
    },
  };
</script>

<template>
  <div>
    <div class="pull-left append-right-10 hidden-xs">
      <i
        aria-hidden="true"
        class="fa fa-key key-icon"
      >
      </i>
    </div>
    <div class="deploy-key-content key-list-item-info">
      <strong class="title">
        {{ deployKey.title }}
      </strong>
      <div class="description">
        {{ deployKey.fingerprint }}
      </div>
      <div
        v-if="deployKey.can_push"
        class="write-access-allowed"
      >
        Write access allowed
      </div>
    </div>
    <div class="deploy-key-content prepend-left-default deploy-key-projects">
      <a
        v-for="(project, i) in deployKey.projects"
        class="label deploy-project-label"
        :href="project.full_path"
        :key="i"
      >
        {{ project.full_name }}
      </a>
    </div>
    <div class="deploy-key-content">
      <span class="key-created-at">
        created {{ timeagoDate }}
      </span>
      <a
        v-if="deployKey.can_edit"
        class="btn btn-sm"
        :href="editDeployKeyPath"
      >
        Edit
      </a>
      <action-btn
        v-if="!isEnabled(deployKey.id)"
        :deploy-key="deployKey"
        type="enable"
      />
      <action-btn
        v-else-if="deployKey.destroyed_when_orphaned && deployKey.almost_orphaned"
        :deploy-key="deployKey"
        btn-css-class="btn-warning"
        type="remove"
      />
      <action-btn
        v-else
        :deploy-key="deployKey"
        btn-css-class="btn-warning"
        type="disable"
      />
    </div>
  </div>
</template>
