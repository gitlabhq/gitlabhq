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
      if (this.hasMultipleCommits) {
        const { last_deployment } = this.environment;
        return this.commitData(last_deployment, 'short_id');
      }

      return this.environment.commitShortSha;
    },

    commitUrl() {
      if (this.hasMultipleCommits) {
        const { last_deployment } = this.environment;
        return this.commitData(last_deployment, 'commit_path');
      }

      return this.environment.commitUrl;
    },

    modalText() {
      const linkStart = `<a class="commit-sha mr-0" href="${escape(this.commitUrl)}">`;
      const commitId = escape(this.commitShortSha);
      const linkEnd = '</a>';
      const name = escape(this.environment.name);
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
    handleChange(event) {
      this.$emit('change', event);
    },

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
    :visible="visible"
    modal-id="confirm-rollback-modal"
    :ok-title="modalActionText"
    ok-variant="danger"
    @ok="onOk"
    @change="handleChange"
  >
    <p v-html="modalText"></p>
  </gl-modal>
</template>
