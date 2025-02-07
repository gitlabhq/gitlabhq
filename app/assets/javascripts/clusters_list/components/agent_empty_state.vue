<script>
import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { I18N_AGENTS_EMPTY_STATE } from '../constants';

export default {
  i18n: I18N_AGENTS_EMPTY_STATE,
  agentDocsUrl: helpPagePath('user/clusters/agent/_index'),
  components: {
    GlEmptyState,
    GlLink,
    GlSprintf,
  },
  inject: ['emptyStateImage'],
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :svg-path="emptyStateImage"
    data-testid="cluster-agent-empty-state"
  >
    <template #description>
      <gl-sprintf :message="$options.i18n.introText">
        <template #link="{ content }">
          <gl-link :href="$options.agentDocsUrl">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </template>
  </gl-empty-state>
</template>
