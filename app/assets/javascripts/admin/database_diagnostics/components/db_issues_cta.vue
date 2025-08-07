<script>
import { GlCard, GlButton, GlIcon } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { SUPPORT_URL } from '~/sessions/new/constants';

export default {
  name: 'DbIssuesCta',
  components: { GlCard, GlButton, GlIcon },
  adminPgUpgradingOsHelpPath: helpPagePath('administration/postgresql/upgrading_os'),
  SUPPORT_URL,
};
</script>

<template>
  <gl-card class="gl-mt-5">
    <template #header>
      <gl-icon name="information-o" class="gl-mr-2" />
      <strong>{{ s__('DatabaseDiagnostics|Issues detected') }}</strong>
    </template>

    <p>
      {{ s__('DatabaseDiagnostics|These issues require manual remediation.') }}
    </p>

    <div class="gl-flex gl-gap-3">
      <gl-button
        :href="$options.adminPgUpgradingOsHelpPath"
        icon="document"
        variant="confirm"
        data-testid="learn-more-button"
      >
        {{ s__('DatabaseDiagnostics|Learn more') }}
      </gl-button>

      <gl-button
        :href="$options.SUPPORT_URL"
        category="secondary"
        data-testid="contact-support-button"
      >
        {{ s__('DatabaseDiagnostics|Contact Support') }}
      </gl-button>
    </div>
  </gl-card>
</template>
