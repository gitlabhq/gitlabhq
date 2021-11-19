<script>
import { GlButton, GlEmptyState, GlLink, GlSprintf, GlModalDirective } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { INSTALL_AGENT_MODAL_ID, I18N_AGENTS_EMPTY_STATE } from '../constants';

export default {
  i18n: I18N_AGENTS_EMPTY_STATE,
  modalId: INSTALL_AGENT_MODAL_ID,
  multipleClustersDocsUrl: helpPagePath('user/project/clusters/multiple_kubernetes_clusters'),
  installDocsUrl: helpPagePath('administration/clusters/kas'),
  components: {
    GlButton,
    GlEmptyState,
    GlLink,
    GlSprintf,
  },
  directives: {
    GlModalDirective,
  },
  inject: ['emptyStateImage'],
  props: {
    isChildComponent: {
      default: false,
      required: false,
      type: Boolean,
    },
  },
};
</script>

<template>
  <gl-empty-state :svg-path="emptyStateImage" title="" class="agents-empty-state">
    <template #description>
      <p class="gl-text-left">
        {{ $options.i18n.introText }}
      </p>
      <p class="gl-text-left">
        <gl-sprintf :message="$options.i18n.multipleClustersText">
          <template #link="{ content }">
            <gl-link
              :href="$options.multipleClustersDocsUrl"
              target="_blank"
              data-testid="multiple-clusters-docs-link"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>

      <p>
        <gl-link :href="$options.installDocsUrl" target="_blank" data-testid="install-docs-link">
          {{ $options.i18n.learnMoreText }}
        </gl-link>
      </p>
    </template>

    <template #actions>
      <gl-button
        v-if="!isChildComponent"
        v-gl-modal-directive="$options.modalId"
        data-testid="integration-primary-button"
        category="primary"
        variant="confirm"
      >
        {{ $options.i18n.primaryButtonText }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
