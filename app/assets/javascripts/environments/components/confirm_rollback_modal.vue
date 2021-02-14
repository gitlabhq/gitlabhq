<script>
/* eslint-disable vue/no-v-html */
/**
 * Render modal to confirm rollback/redeploy.
 */

import { GlModal } from '@gitlab/ui';
import { escape } from 'lodash';
import { s__, sprintf } from '~/locale';

import eventHub from '../event_hub';

export default {
  name: 'ConfirmRollbackModal',

  components: {
    GlModal,
  },

  props: {
    environment: {
      type: Object,
      required: true,
    },
  },

  computed: {
    modalTitle() {
      const title = this.environment.isLastDeployment
        ? s__('Environments|Re-deploy environment %{name}?')
        : s__('Environments|Rollback environment %{name}?');

      return sprintf(title, {
        name: escape(this.environment.name),
      });
    },

    commitShortSha() {
      const { last_deployment } = this.environment;
      return this.commitData(last_deployment, 'short_id');
    },

    commitUrl() {
      const { last_deployment } = this.environment;
      return this.commitData(last_deployment, 'commit_path');
    },

    commitTitle() {
      const { last_deployment } = this.environment;
      return this.commitData(last_deployment, 'title');
    },

    modalText() {
      const linkStart = `<a class="commit-sha mr-0" href="${escape(this.commitUrl)}">`;
      const commitId = escape(this.commitShortSha);
      const linkEnd = '</a>';
      const name = escape(this.name);
      const body = this.environment.isLastDeployment
        ? s__(
            'Environments|This action will relaunch the job for commit %{linkStart}%{commitId}%{linkEnd}, putting the environment in a previous version. Are you sure you want to continue?',
          )
        : s__(
            'Environments|This action will run the job defined by %{name} for commit %{linkStart}%{commitId}%{linkEnd} putting the environment in a previous version. You can revert it by re-deploying the latest version of your application. Are you sure you want to continue?',
          );
      return sprintf(
        body,
        {
          commitId,
          linkStart,
          linkEnd,
          name,
        },
        false,
      );
    },

    modalActionText() {
      return this.environment.isLastDeployment
        ? s__('Environments|Re-deploy')
        : s__('Environments|Rollback');
    },
  },

  methods: {
    onOk() {
      eventHub.$emit('rollbackEnvironment', this.environment);
    },

    commitData(lastDeployment, key) {
      if (lastDeployment && lastDeployment.commit) {
        return lastDeployment.commit[key];
      }

      return '';
    },
  },
};
</script>
<template>
  <gl-modal
    :title="modalTitle"
    modal-id="confirm-rollback-modal"
    :ok-title="modalActionText"
    ok-variant="danger"
    @ok="onOk"
  >
    <p v-html="modalText"></p>
  </gl-modal>
</template>
