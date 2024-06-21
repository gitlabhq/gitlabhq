<script>
import { GlButton, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
import { translations } from '~/environments/environment_details/constants';
import ActionsComponent from '~/environments/components/environment_actions.vue';
import setEnvironmentToRollback from '~/environments/graphql/mutations/set_environment_to_rollback.mutation.graphql';

const EnvironmentApprovalComponent = import(
  'ee_component/environments/components/environment_approval.vue'
);

export default {
  components: {
    GlButton,
    ActionsComponent,
    EnvironmentApproval: () => EnvironmentApprovalComponent,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  props: {
    actions: {
      // actions shape:
      /* Array<{
           playable: boolean,
           playPath: url,
           name: string
           scheduledAt: ISO_timestamp | null
      }>
      */
      type: Array,
      required: true,
    },
    rollback: {
      // rollback shape:
      /*
      {
        id: string,
        name: string,
        lastDeployment: {
          commit: Commit,
          isLast: boolean,
        },
        retryUrl: url,
      };
      */
      type: Object,
      required: false,
      default: null,
    },
    // approvalEnvironment shape:
    /* {
         isApprovalActionAvailable: boolean,
         deploymentIid: string,
         environment: {
           name: string,
           tier: string,
           requiredApprovalCount: number,
       },
    */
    approvalEnvironment: {
      type: Object,
      required: false,
      default: () => ({
        isApprovalActionAvailable: false,
      }),
    },
    deploymentWebPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    isRollbackAvailable() {
      return Boolean(this.rollback?.lastDeployment);
    },
    rollbackIcon() {
      return this.rollback.lastDeployment.isLast ? 'repeat' : 'redo';
    },
    isActionsShown() {
      return this.actions.length > 0;
    },
    deploymentIid() {
      return this.approvalEnvironment.deploymentIid;
    },
    environment() {
      return this.approvalEnvironment.environment;
    },
    rollbackButtonTitle() {
      return this.rollback.lastDeployment?.isLast
        ? translations.redeployButtonTitle
        : translations.rollbackButtonTitle;
    },
  },
  methods: {
    onRollbackClick() {
      this.$apollo.mutate({
        mutation: setEnvironmentToRollback,
        variables: {
          environment: this.rollback,
        },
      });
    },
  },
};
</script>
<template>
  <div>
    <actions-component v-if="isActionsShown" :actions="actions" graphql />
    <gl-button
      v-if="isRollbackAvailable"
      v-gl-modal.confirm-rollback-modal
      v-gl-tooltip
      :title="rollbackButtonTitle"
      :icon="rollbackIcon"
      :aria-label="rollbackButtonTitle"
      @click="onRollbackClick"
    />
    <environment-approval
      v-if="approvalEnvironment.isApprovalActionAvailable"
      :required-approval-count="environment.requiredApprovalCount"
      :deployment-web-path="deploymentWebPath"
      :show-text="false"
    />
  </div>
</template>
