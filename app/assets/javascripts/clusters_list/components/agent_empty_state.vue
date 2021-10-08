<script>
import { GlButton, GlEmptyState, GlLink, GlSprintf, GlAlert, GlModalDirective } from '@gitlab/ui';
import { INSTALL_AGENT_MODAL_ID } from '../constants';

export default {
  modalId: INSTALL_AGENT_MODAL_ID,
  components: {
    GlButton,
    GlEmptyState,
    GlLink,
    GlSprintf,
    GlAlert,
  },
  directives: {
    GlModalDirective,
  },
  inject: [
    'emptyStateImage',
    'projectPath',
    'agentDocsUrl',
    'installDocsUrl',
    'getStartedDocsUrl',
    'integrationDocsUrl',
  ],
  props: {
    hasConfigurations: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    repositoryPath() {
      return `/${this.projectPath}`;
    },
  },
};
</script>

<template>
  <gl-empty-state
    :svg-path="emptyStateImage"
    :title="s__('ClusterAgents|Integrate Kubernetes with a GitLab Agent')"
    class="empty-state--agent"
  >
    <template #description>
      <p class="mw-460 gl-mx-auto">
        <gl-sprintf
          :message="
            s__(
              'ClusterAgents|The GitLab Kubernetes Agent allows an Infrastructure as Code, GitOps approach to integrating Kubernetes clusters with GitLab. %{linkStart}Learn more.%{linkEnd}',
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="agentDocsUrl" target="_blank" data-testid="agent-docs-link">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>

      <p class="mw-460 gl-mx-auto">
        <gl-sprintf
          :message="
            s__(
              'ClusterAgents|The GitLab Agent also requires %{linkStart}enabling the Agent Server%{linkEnd}',
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="installDocsUrl" target="_blank" data-testid="install-docs-link">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>

      <gl-alert
        v-if="!hasConfigurations"
        variant="warning"
        class="gl-mb-5 text-left"
        :dismissible="false"
      >
        {{
          s__(
            'ClusterAgents|To install an Agent you should create an agent directory in the Repository first. We recommend that you add the Agent configuration to the directory before you start the installation process.',
          )
        }}

        <template #actions>
          <gl-button
            category="primary"
            variant="info"
            :href="getStartedDocsUrl"
            target="_blank"
            class="gl-ml-0!"
          >
            {{ s__('ClusterAgents|Read more about getting started') }}
          </gl-button>
          <gl-button category="secondary" variant="info" :href="repositoryPath">
            {{ s__('ClusterAgents|Go to the repository') }}
          </gl-button>
        </template>
      </gl-alert>
    </template>

    <template #actions>
      <gl-button
        v-gl-modal-directive="$options.modalId"
        :disabled="!hasConfigurations"
        data-testid="integration-primary-button"
        category="primary"
        variant="success"
      >
        {{ s__('ClusterAgents|Integrate with the GitLab Agent') }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
