<script>
import { GlButton, GlEmptyState, GlLink, GlSprintf, GlAlert, GlModalDirective } from '@gitlab/ui';
import { INSTALL_AGENT_MODAL_ID, I18N_AGENTS_EMPTY_STATE } from '../constants';

export default {
  i18n: I18N_AGENTS_EMPTY_STATE,
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
    'multipleClustersDocsUrl',
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
  <gl-empty-state :svg-path="emptyStateImage" title="" class="agents-empty-state">
    <template #description>
      <p class="mw-460 gl-mx-auto gl-text-left">
        {{ $options.i18n.introText }}
      </p>
      <p class="mw-460 gl-mx-auto gl-text-left">
        <gl-sprintf :message="$options.i18n.multipleClustersText">
          <template #link="{ content }">
            <gl-link
              :href="multipleClustersDocsUrl"
              target="_blank"
              data-testid="multiple-clusters-docs-link"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>

      <p class="mw-460 gl-mx-auto">
        <gl-link :href="installDocsUrl" target="_blank" data-testid="install-docs-link">
          {{ $options.i18n.learnMoreText }}
        </gl-link>
      </p>

      <gl-alert
        v-if="!hasConfigurations"
        variant="warning"
        class="gl-mb-5 text-left"
        :dismissible="false"
      >
        {{ $options.i18n.warningText }}

        <template #actions>
          <gl-button
            category="primary"
            variant="info"
            :href="getStartedDocsUrl"
            target="_blank"
            class="gl-ml-0!"
          >
            {{ $options.i18n.readMoreText }}
          </gl-button>
          <gl-button category="secondary" variant="info" :href="repositoryPath">
            {{ $options.i18n.repositoryButtonText }}
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
        variant="confirm"
      >
        {{ $options.i18n.primaryButtonText }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
