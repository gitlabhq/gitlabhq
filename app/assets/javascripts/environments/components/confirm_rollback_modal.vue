<script>
/**
 * Render modal to confirm rollback/redeploy.
 */
import { GlModal, GlSprintf, GlLink } from '@gitlab/ui';
import { escape } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import csrf from '~/lib/utils/csrf';
import { __, s__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

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
          return (
            // data shape comming from REST and GraphQL is unfortunately different
            // once we fully migrate to GraphQL it could be streamlined
            this.commitData(lastDeployment, 'commitPath') ||
            this.commitData(lastDeployment, 'webUrl')
          );
        }

        const { last_deployment } = this.environment;
        return this.commitData(last_deployment, 'commit_path');
      }

      return this.environment.commitUrl;
    },
    modalActionText() {
      return this.isLastDeployment
        ? s__('Environments|Re-deploy environment')
        : s__('Environments|Rollback environment');
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
    modalBodyText() {
      return this.isLastDeployment
        ? s__(
            'Environments|This action will %{docsStart}retry the latest deployment%{docsEnd} with the commit %{commitId}, for this environment. Are you sure you want to continue?',
          )
        : s__(
            'Environments|This action will %{docsStart}roll back this environment%{docsEnd} to a previously successful deployment for commit %{commitId}. Are you sure you want to continue?',
          );
    },
  },
  methods: {
    handleChange(event) {
      this.$emit('change', event);
    },
    onOk() {
      if (this.graphql) {
        this.$apollo
          .mutate({
            mutation: rollbackEnvironment,
            variables: { environment: this.environment },
          })
          .then(() => {
            this.$emit('rollback');
          })
          .catch((e) => {
            Sentry.captureException(e);
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
  },
  docsPath: helpPagePath('ci/environments/deployments.md', {
    anchor: 'retry-or-roll-back-a-deployment',
  }),
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
    <gl-sprintf :message="modalBodyText">
      <template #commitId>
        <gl-link :href="commitUrl" target="_blank" class="commit-sha mr-0">{{
          commitShortSha
        }}</gl-link>
      </template>
      <template #docs="{ content }">
        <gl-link :href="$options.docsPath" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </gl-modal>
</template>
