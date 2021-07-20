<script>
import { refreshUserMergeRequestCounts } from '~/commons/nav/user_merge_requests';
import createFlash from '~/flash';
import { __ } from '~/locale';
import eventHub from '~/sidebar/event_hub';
import Store from '~/sidebar/stores/sidebar_store';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import AssigneeTitle from './assignee_title.vue';
import Assignees from './assignees.vue';
import AssigneesRealtime from './assignees_realtime.vue';

export default {
  name: 'SidebarAssignees',
  components: {
    AssigneeTitle,
    Assignees,
    AssigneesRealtime,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    mediator: {
      type: Object,
      required: true,
    },
    field: {
      type: String,
      required: true,
    },
    signedIn: {
      type: Boolean,
      required: false,
      default: false,
    },
    issuableType: {
      type: String,
      required: false,
      default: 'issue',
    },
    issuableIid: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    issuableId: {
      type: Number,
      required: true,
    },
    assigneeAvailabilityStatus: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      store: new Store(),
      loading: false,
    };
  },
  computed: {
    shouldEnableRealtime() {
      // Note: Realtime is only available on issues right now, future support for MR wil be built later.
      return this.glFeatures.realTimeIssueSidebar && this.issuableType === 'issue';
    },
    queryVariables() {
      return {
        iid: this.issuableIid,
        fullPath: this.projectPath,
      };
    },
    relativeUrlRoot() {
      return gon.relative_url_root ?? '';
    },
  },
  created() {
    this.removeAssignee = this.store.removeAssignee.bind(this.store);
    this.addAssignee = this.store.addAssignee.bind(this.store);
    this.removeAllAssignees = this.store.removeAllAssignees.bind(this.store);

    // Get events from deprecatedJQueryDropdown
    eventHub.$on('sidebar.removeAssignee', this.removeAssignee);
    eventHub.$on('sidebar.addAssignee', this.addAssignee);
    eventHub.$on('sidebar.removeAllAssignees', this.removeAllAssignees);
    eventHub.$on('sidebar.saveAssignees', this.saveAssignees);
  },
  beforeDestroy() {
    eventHub.$off('sidebar.removeAssignee', this.removeAssignee);
    eventHub.$off('sidebar.addAssignee', this.addAssignee);
    eventHub.$off('sidebar.removeAllAssignees', this.removeAllAssignees);
    eventHub.$off('sidebar.saveAssignees', this.saveAssignees);
  },
  methods: {
    assignSelf() {
      // Notify gl dropdown that we are now assigning to current user
      this.$el.parentElement.dispatchEvent(new Event('assignYourself'));

      this.mediator.assignYourself();
      this.saveAssignees();
    },
    saveAssignees() {
      this.loading = true;

      this.mediator
        .saveAssignees(this.field)
        .then(() => {
          this.loading = false;
          this.store.resetChanging();

          refreshUserMergeRequestCounts();
        })
        .catch(() => {
          this.loading = false;
          return createFlash({
            message: __('Error occurred when saving assignees'),
          });
        });
    },
    exposeAvailabilityStatus(users) {
      return users.map(({ username, ...rest }) => ({
        ...rest,
        username,
        availability: this.assigneeAvailabilityStatus[username] || '',
      }));
    },
  },
};
</script>

<template>
  <div>
    <assignees-realtime
      v-if="shouldEnableRealtime"
      :issuable-type="issuableType"
      :issuable-id="issuableId"
      :query-variables="queryVariables"
      :mediator="mediator"
    />
    <assignee-title
      :number-of-assignees="store.assignees.length"
      :loading="loading || store.isFetching.assignees"
      :editable="store.editable"
      :show-toggle="!signedIn"
      :changing="store.changing"
    />
    <assignees
      v-if="!store.isFetching.assignees"
      :root-path="relativeUrlRoot"
      :users="exposeAvailabilityStatus(store.assignees)"
      :editable="store.editable"
      :issuable-type="issuableType"
      @assign-self="assignSelf"
    />
  </div>
</template>
