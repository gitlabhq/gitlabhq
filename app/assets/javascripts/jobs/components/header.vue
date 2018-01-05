<script>
  import ciHeader from '../../vue_shared/components/header_ci_component.vue';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';

  export default {
    name: 'jobHeaderSection',
    props: {
      job: {
        type: Object,
        required: true,
      },
      isLoading: {
        type: Boolean,
        required: true,
      },
    },
    components: {
      ciHeader,
      loadingIcon,
    },
    data() {
      return {
        actions: this.getActions(),
      };
    },
    computed: {
      status() {
        return this.job && this.job.status;
      },
      shouldRenderContent() {
        return !this.isLoading && Object.keys(this.job).length;
      },
      jobStarted() {
        return this.job.started;
      },
    },
    methods: {
      getActions() {
        const actions = [];

        if (this.job.new_issue_path) {
          actions.push({
            label: 'New issue',
            path: this.job.new_issue_path,
            cssClass: 'js-new-issue btn btn-new btn-inverted visible-md-block visible-lg-block',
            type: 'link',
          });
        }
        return actions;
      },
    },
    watch: {
      job() {
        this.actions = this.getActions();
      },
    },
  };
</script>
<template>
  <div class="js-build-header build-header top-area">
    <ci-header
      v-if="shouldRenderContent"
      :status="status"
      item-name="Job"
      :item-id="job.id"
      :time="job.created_at"
      :user="job.user"
      :actions="actions"
      :has-sidebar-button="true"
      :should-render-triggered-label="jobStarted"
    />
    <loading-icon
      v-if="isLoading"
      size="2"
      />
  </div>
</template>
