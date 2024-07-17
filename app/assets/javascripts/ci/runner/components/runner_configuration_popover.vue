<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'RunnerConfigurationPopover',
  components: {
    GlLink,
    GlSprintf,
    HelpPopover,
  },
  // eslint-disable-next-line local-rules/require-valid-help-page-path
  runnerEntryHelpPath: helpPagePath('/runner/configuration/advanced-configuration.md', {
    anchor: 'the-runners-section',
  }),
};
</script>

<template>
  <help-popover>
    <gl-sprintf
      :message="
        s__(
          'Runners|A runner configuration is where you configure runners based on your requirements. Each runner in this table represents a %{linkStart}single runner entry%{linkEnd} in the %{codeStart}config.toml%{codeEnd}. Multiple runners can be linked to the same configuration. When there are multiple runners in a configuration, the one that contacted GitLab most recently displays here.',
        )
      "
    >
      <template #link="{ content }"
        ><gl-link :href="$options.runnerEntryHelpPath">{{ content }}</gl-link></template
      >
      <template #code="{ content }"
        ><code>{{ content }}</code></template
      >
    </gl-sprintf>
  </help-popover>
</template>
