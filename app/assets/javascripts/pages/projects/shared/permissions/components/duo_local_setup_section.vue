<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

export default {
  name: 'DuoLocalSetupSection',
  components: { GlButton, GlIcon },
  cards: [
    {
      icon: 'monitor',
      title: s__('DuoAgentPlatform|IDE extensions'),
      description: s__('DuoAgentPlatform|VS Code · JetBrains · Visual Studio'),
      linkText: s__('DuoAgentPlatform|Get the extension'),
      href: helpPagePath('editor_extensions/_index.md'),
    },
    {
      icon: 'terminal',
      title: s__('DuoAgentPlatform|GitLab CLI (glab)'),
      description: s__(
        'DuoAgentPlatform|Manage merge requests, issues, and pipelines, and run Orbit Local from the terminal.',
      ),
      linkText: s__('DuoAgentPlatform|Install glab'),
      href: helpPagePath('editor_extensions/gitlab_cli/_index.md'),
    },
    {
      icon: 'tanuki-ai',
      title: s__('DuoAgentPlatform|GitLab Duo CLI'),
      description: s__('DuoAgentPlatform|Run flows and agentic chat from the terminal.'),
      linkText: s__('DuoAgentPlatform|Install GitLab Duo CLI'),
      href: helpPagePath('user/gitlab_duo_cli/set_up.md'),
    },
  ],
  i18n: {
    heading: s__('DuoAgentPlatform|Local setup'),
    subtitle: s__('DuoAgentPlatform|Tools you can install to use GitLab Duo.'),
  },
};
</script>

<template>
  <div class="gl-@container" data-testid="local-setup-section">
    <div class="gl-mb-3 gl-flex gl-flex-wrap gl-items-baseline gl-gap-3">
      <span class="gl-font-bold">{{ $options.i18n.heading }}</span>
      <span class="gl-text-sm gl-text-subtle">{{ $options.i18n.subtitle }}</span>
    </div>

    <div class="gl-grid gl-grid-cols-1 gl-gap-4 @md:gl-grid-cols-3">
      <div
        v-for="card in $options.cards"
        :key="card.title"
        class="gl-border gl-flex gl-flex-col gl-gap-3 gl-rounded-lg gl-p-4"
        data-testid="local-setup-card"
      >
        <div class="gl-flex gl-items-center gl-gap-2">
          <gl-icon :name="card.icon" :size="16" variant="subtle" class="gl-shrink-0" />
          <span class="gl-font-bold">{{ card.title }}</span>
        </div>
        <div class="gl-grow gl-text-sm gl-text-subtle">{{ card.description }}</div>
        <gl-button
          category="tertiary"
          size="small"
          icon="external-link"
          :href="card.href"
          target="_blank"
          class="gl-self-start"
          data-testid="local-setup-link"
        >
          {{ card.linkText }}
        </gl-button>
      </div>
    </div>
  </div>
</template>
