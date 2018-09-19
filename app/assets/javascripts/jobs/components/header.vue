<script>
import ciHeader from '../../vue_shared/components/header_ci_component.vue';
import callout from '../../vue_shared/components/callout.vue';

export default {
  name: 'JobHeaderSection',
  components: {
    ciHeader,
    callout,
  },
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
    shouldRenderReason() {
      return !!(this.job.status && this.job.callout_message);
    },
    /**
     * When job has not started the key will be `false`
     * When job started the key will be a string with a date.
     */
    jobStarted() {
      return !this.job.started === false;
    },
    headerTime() {
      return this.jobStarted ? this.job.started : this.job.created_at;
    },
  },
  watch: {
    job() {
      this.actions = this.getActions();
    },
  },
  methods: {
    getActions() {
      const actions = [];

      if (this.job.new_issue_path) {
        actions.push({
          label: 'New issue',
          path: this.job.new_issue_path,
          cssClass: 'js-new-issue btn btn-new btn-inverted d-none d-md-block d-lg-block d-xl-block',
          type: 'link',
        });
      }
      return actions;
    },
  },
};
</script>
<template>
  <header>
    <div class="js-build-header build-header top-area">
      <ci-header
        v-if="shouldRenderContent"
        :status="status"
        :item-id="job.id"
        :time="headerTime"
        :user="job.user"
        :actions="actions"
        :has-sidebar-button="true"
        :should-render-triggered-label="jobStarted"
        item-name="Job"
      />
      <gl-loading-icon
        v-if="isLoading"
        :size="2"
        class="prepend-top-default append-bottom-default"
      />
    </div>

    <callout
      v-if="shouldRenderReason"
      :message="job.callout_message"
    />
  </header>
</template>
