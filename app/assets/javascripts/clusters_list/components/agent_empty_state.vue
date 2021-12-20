<script>
import { GlButton, GlEmptyState, GlLink, GlSprintf, GlModalDirective } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { INSTALL_AGENT_MODAL_ID, I18N_AGENTS_EMPTY_STATE } from '../constants';

export default {
  i18n: I18N_AGENTS_EMPTY_STATE,
  modalId: INSTALL_AGENT_MODAL_ID,
  agentDocsUrl: helpPagePath('user/clusters/agent/index'),
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
        <gl-sprintf :message="$options.i18n.introText">
          <template #link="{ content }">
            <gl-link :href="$options.agentDocsUrl">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
    </template>

    <template #actions>
      <gl-button
        v-if="!isChildComponent"
        v-gl-modal-directive="$options.modalId"
        category="primary"
        variant="confirm"
      >
        {{ $options.i18n.buttonText }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
