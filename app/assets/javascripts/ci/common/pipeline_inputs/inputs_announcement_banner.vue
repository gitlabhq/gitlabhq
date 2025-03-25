<script>
import { GlBanner } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';

export default {
  name: 'InputsAnnouncementBanner',
  components: { GlBanner, UserCalloutDismisser },
  inputDocLink: helpPagePath('ci/yaml/inputs', {
    anchor: 'define-input-parameters-with-specinputs',
  }),
};
</script>

<template>
  <user-callout-dismisser feature-name="pipeline_inputs_announcement_banner">
    <template #default="{ shouldShowCallout, dismiss }">
      <gl-banner
        v-if="shouldShowCallout"
        class="gl-mb-4 gl-mt-2"
        :title="s__('Pipelines|Pipeline inputs now available!')"
        variant="introduction"
        :button-text="s__('Pipelines|Start using inputs')"
        :button-link="$options.inputDocLink"
        @close="dismiss"
      >
        <p>
          {{
            s__(
              'Pipelines|Use inputs to increase the flexibility of your CI/CD configuration files and enhance reusability across your projects.',
            )
          }}
        </p>
      </gl-banner>
    </template>
  </user-callout-dismisser>
</template>
