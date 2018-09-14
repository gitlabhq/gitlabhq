<script>
  /* eslint-disable vue/require-default-prop */
  import issuableApp from '~/issue_show/components/app.vue';
  import relatedIssuesRoot from 'ee/related_issues/components/related_issues_root.vue';
  import issuableAppEventHub from '~/issue_show/event_hub';
  import epicSidebar from '../../sidebar/components/sidebar_app.vue';
  import SidebarContext from '../sidebar_context';
  import epicHeader from './epic_header.vue';

  export default {
    name: 'EpicShowApp',
    components: {
      epicHeader,
      epicSidebar,
      issuableApp,
      relatedIssuesRoot,
    },
    props: {
      epicId: {
        type: Number,
        required: true,
      },
      endpoint: {
        type: String,
        required: true,
      },
      updateEndpoint: {
        type: String,
        required: true,
      },
      canUpdate: {
        required: true,
        type: Boolean,
      },
      canDestroy: {
        required: true,
        type: Boolean,
      },
      canAdmin: {
        required: true,
        type: Boolean,
      },
      markdownPreviewPath: {
        type: String,
        required: true,
      },
      markdownDocsPath: {
        type: String,
        required: true,
      },
      groupPath: {
        type: String,
        required: true,
      },
      initialTitleHtml: {
        type: String,
        required: true,
      },
      initialTitleText: {
        type: String,
        required: true,
      },
      initialDescriptionHtml: {
        type: String,
        required: false,
        default: '',
      },
      initialDescriptionText: {
        type: String,
        required: false,
        default: '',
      },
      created: {
        type: String,
        required: true,
      },
      author: {
        type: Object,
        required: true,
      },
      issueLinksEndpoint: {
        type: String,
        required: true,
      },
      startDateIsFixed: {
        type: Boolean,
        required: true,
      },
      startDateFixed: {
        type: String,
        required: false,
        default: '',
      },
      startDateFromMilestones: {
        type: String,
        required: false,
        default: '',
      },
      startDate: {
        type: String,
        required: false,
      },
      dueDateIsFixed: {
        type: Boolean,
        required: true,
      },
      dueDateFixed: {
        type: String,
        required: false,
        default: '',
      },
      dueDateFromMilestones: {
        type: String,
        required: false,
        default: '',
      },
      endDate: {
        type: String,
        required: false,
      },
      startDateSourcingMilestoneTitle: {
        type: String,
        required: false,
        default: '',
      },
      dueDateSourcingMilestoneTitle: {
        type: String,
        required: false,
        default: '',
      },
      labels: {
        type: Array,
        required: true,
      },
      participants: {
        type: Array,
        required: true,
      },
      subscribed: {
        type: Boolean,
        required: true,
      },
      todoExists: {
        type: Boolean,
        required: true,
      },
      namespace: {
        type: String,
        required: false,
        default: '#',
      },
      labelsPath: {
        type: String,
        required: true,
      },
      toggleSubscriptionPath: {
        type: String,
        required: true,
      },
      todoPath: {
        type: String,
        required: true,
      },
      todoDeletePath: {
        type: String,
        required: false,
        default: '',
      },
      labelsWebUrl: {
        type: String,
        required: true,
      },
      epicsWebUrl: {
        type: String,
        required: true,
      },
    },
    data() {
      return {
        // Epics specific configuration
        issuableRef: '',
        projectPath: this.groupPath,
        projectNamespace: '',
      };
    },
    mounted() {
      this.sidebarContext = new SidebarContext();
    },
    methods: {
      deleteEpic() {
        issuableAppEventHub.$emit('delete.issuable');
      },
    },
  };
</script>

<template>
  <div class="epic-page-container">
    <epic-header
      :author="author"
      :created="created"
      :can-delete="canDestroy"
      @deleteEpic="deleteEpic"
    />
    <div class="issuable-details content-block">
      <div class="detail-page-description">
        <issuable-app
          :can-update="canUpdate"
          :can-destroy="canDestroy"
          :endpoint="endpoint"
          :update-endpoint="updateEndpoint"
          :issuable-ref="issuableRef"
          :initial-title-html="initialTitleHtml"
          :initial-title-text="initialTitleText"
          :initial-description-html="initialDescriptionHtml"
          :initial-description-text="initialDescriptionText"
          :markdown-preview-path="markdownPreviewPath"
          :markdown-docs-path="markdownDocsPath"
          :project-path="projectPath"
          :project-namespace="projectNamespace"
          :show-inline-edit-button="true"
          :show-delete-button="false"
          :enable-autocomplete="true"
          issuable-type="epic"
        />
      </div>
      <epic-sidebar
        :epic-id="epicId"
        :endpoint="endpoint"
        :editable="canUpdate"
        :initial-start-date-is-fixed="startDateIsFixed"
        :initial-start-date-fixed="startDateFixed"
        :start-date-from-milestones="startDateFromMilestones"
        :initial-start-date="startDate"
        :initial-due-date-is-fixed="dueDateIsFixed"
        :initial-due-date-fixed="dueDateFixed"
        :due-date-from-milestones="dueDateFromMilestones"
        :initial-end-date="endDate"
        :start-date-sourcing-milestone-title="startDateSourcingMilestoneTitle"
        :due-date-sourcing-milestone-title="dueDateSourcingMilestoneTitle"
        :initial-labels="labels"
        :initial-participants="participants"
        :initial-subscribed="subscribed"
        :initial-todo-exists="todoExists"
        :namespace="namespace"
        :update-path="updateEndpoint"
        :labels-path="labelsPath"
        :toggle-subscription-path="toggleSubscriptionPath"
        :todo-path="todoPath"
        :todo-delete-path="todoDeletePath"
        :labels-web-url="labelsWebUrl"
        :epics-web-url="epicsWebUrl"
      />
      <related-issues-root
        :endpoint="issueLinksEndpoint"
        :can-admin="canAdmin"
        :can-reorder="canAdmin"
        :allow-auto-complete="false"
        title="Issues"
      />
    </div>
  </div>
</template>
