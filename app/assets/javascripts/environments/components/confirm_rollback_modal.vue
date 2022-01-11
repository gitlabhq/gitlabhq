<script>
/**
 * Render modal to confirm rollback/redeploy.
 */
import { GlModal, GlSprintf, GlLink } from '@gitlab/ui';
import { escape } from 'lodash';
import csrf from '~/lib/utils/csrf';
import { __, s__, sprintf } from '~/locale';

import rollbackEnvironment from '../graphql/mutations/rollback_environment.mutation.graphql';
import eventHub from '../event_hub';

export default {
  name: 'ConfirmRollbackModal',
  components: {
    GlModal,
    GlSprintf,
    GlLink,
  },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    environment: {
      type: Object,
      required: true,
    },
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasMultipleCommits: {
      type: Boolean,
      required: false,
      default: true,
    },
    retryUrl: {
      type: String,
      required: false,
      default: null,
    },
    graphql: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    modalTitle() {
      const title = this.isLastDeployment
        ? s__('Environments|Re-deploy environment %{name}?')
        : s__('Environments|Rollback environment %{name}?');

      return sprintf(title, {
        name: escape(this.environment.name),
      });
    },
    commitShortSha() {
      if (this.hasMultipleCommits) {
        if (this.graphql) {
          const { lastDeployment } = this.environment;
          return this.commitData(lastDeployment, 'shortId');
        }

        const { last_deployment } = this.environment;
        return this.commitData(last_deployment, 'short_id');
      }

      return this.environment.commitShortSha;
    },
    commitUrl() {
      if (this.hasMultipleCommits) {
        if (this.graphql) {
          const { lastDeployment } = this.environment;
          return this.commitData(lastDeployment, 'commitPath');
        }

        const { last_deployment } = this.environment;
        return this.commitData(last_deployment, 'commit_path');
      }

      return this.environment.commitUrl;
    },
    modalActionText() {
      return this.isLastDeployment ? s__('Environments|Re-deploy') : s__('Environments|Rollback');
    },
    primaryProps() {
      let attributes = [{ variant: 'danger' }];

      if (this.retryUrl) {
        attributes = [...attributes, { 'data-method': 'post' }, { href: this.retryUrl }];
      }

      return {
        text: this.modalActionText,
        attributes,
      };
    },
    isLastDeployment() {
      return this.environment?.isLastDeployment || this.environment?.lastDeployment?.isLast;
    },
  },
  methods: {
    handleChange(event) {
      this.$emit('change', event);
    },
    onOk() {
      if (this.graphql) {
        this.$apollo.mutate({
          mutation: rollbackEnvironment,
          variables: { environment: this.environment },
        });
      } else {
        eventHub.$emit('rollbackEnvironment', this.environment);
      }
    },
    commitData(lastDeployment, key) {
      return lastDeployment?.commit?.[key] ?? '';
    },
  },
  csrf,
  cancelProps: {
    text: __('Cancel'),
    attributes: [{ variant: 'danger' }],
  },
};
</script>
<template>
  <gl-modal
    :title="modalTitle"
    :visible="visible"
    :action-cancel="$options.cancelProps"
    :action-primary="primaryProps"
    modal-id="confirm-rollback-modal"
    @ok="onOk"
    @change="handleChange"
  >
    <gl-sprintf
      v-if="environment.isLastDeployment"
      :message="
        s__(
          'Environments|This action will relaunch the job for commit %{linkStart}%{commitId}%{linkEnd}, putting the environment in a previous version. Are you sure you want to continue?',
        )
      "
    >
      <template #link>
        <gl-link :href="commitUrl" target="_blank" class="commit-sha mr-0">{{
          commitShortSha
        }}</gl-link>
      </template>
    </gl-sprintf>
    <gl-sprintf
      v-else
      :message="
        s__(
          'Environments|This action will run the job defined by %{name} for commit %{linkStart}%{commitId}%{linkEnd} putting the environment in a previous version. You can revert it by re-deploying the latest version of your application. Are you sure you want to continue?',
        )
      "
    >
      <template #name>{{ environment.name }}</template>
      <template #link>
        <gl-link :href="commitUrl" target="_blank" class="commit-sha mr-0">{{
          commitShortSha
        }}</gl-link>
      </template>
    </gl-sprintf>
  </gl-modal>
</template>
