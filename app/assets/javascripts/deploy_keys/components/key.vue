<script>
  import actionBtn from './action_btn.vue';

  export default {
    props: {
      deployKey: {
        type: Object,
        required: true,
      },
      enabled: {
        type: Boolean,
        required: false,
        default: true,
      },
      store: {
        type: Object,
        required: true,
      },
    },
    components: {
      actionBtn,
    },
    computed: {
      timeagoDate() {
        return gl.utils.getTimeago().format(this.deployKey.created_at);
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
        class="fa fa-key key-icon">
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
        class="write-access-allowed">
        Write access allowed
      </div>
    </div>
    <div class="deploy-key-content prepend-left-default deploy-key-projects">
      <a
        v-for="project in deployKey.projects"
        class="label deploy-project-label"
        :href="project.full_path">
        {{ project.full_name }}
      </a>
    </div>
    <div class="deploy-key-content">
      <span class="key-created-at">
        created {{ timeagoDate }}
      </span>
      <action-btn
        v-if="!isEnabled(deployKey.id)"
        :deploy-key="deployKey"
        type="enable"/>
      <action-btn
        v-else-if="deployKey.destroyed_when_orphaned && deployKey.almost_orphaned"
        :deploy-key="deployKey"
        btn-css-class="btn-warning"
        type="remove" />
      <action-btn
        v-else
        :deploy-key="deployKey"
        btn-css-class="btn-warning"
        type="disable" />
    </div>
  </div>
</template>
