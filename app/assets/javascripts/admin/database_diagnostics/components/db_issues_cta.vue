<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { SUPPORT_URL } from '~/sessions/new/constants';

export default {
  name: 'DbIssuesCta',
  components: { GlButton, GlIcon },
  adminPgUpgradingOsHelpPath: helpPagePath('administration/postgresql/upgrading_os'),
  SUPPORT_URL,
};
</script>

<template>
  <div>
    <h4 class="gl-heading-5">
      <gl-icon name="error" variant="danger" class="gl-mr-2" />
      {{ s__('DatabaseDiagnostics|Issues detected') }}
    </h4>

    <p>
      {{ s__('DatabaseDiagnostics|These issues require manual remediation.') }}
    </p>

    <div class="gl-flex gl-gap-3">
      <gl-button
        :href="$options.adminPgUpgradingOsHelpPath"
        variant="confirm"
        data-testid="learn-more-button"
      >
        {{ s__('DatabaseDiagnostics|How to fix these?') }}
      </gl-button>

      <gl-button
        :href="$options.SUPPORT_URL"
        category="secondary"
        data-testid="contact-support-button"
      >
        {{ s__('DatabaseDiagnostics|Contact support') }}
      </gl-button>
    </div>
  </div>
</template>
