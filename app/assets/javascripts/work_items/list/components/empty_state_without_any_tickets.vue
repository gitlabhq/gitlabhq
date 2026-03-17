<script>
import emptyStateSvg from '@gitlab/svgs/dist/illustrations/empty-state/empty-service-desk-md.svg';
import { GlEmptyState, GlLink } from '@gitlab/ui';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { __ } from '~/locale';

export default {
  name: 'EmptyStateWithoutAnyTickets',
  emptyStateSvg,
  components: {
    GlEmptyState,
    GlLink,
  },
  inject: [
    'signInPath',
    'canAdminIssue',
    'isServiceDeskEnabled',
    'serviceDeskEmailAddress',
    'serviceDeskHelpPath',
  ],
  data() {
    return {
      isLoggedIn: isLoggedIn(),
    };
  },
  computed: {
    canSeeEmailAddress() {
      return this.canAdminIssue && this.isServiceDeskEnabled;
    },
    primaryButtonLink() {
      return this.isLoggedIn ? undefined : this.signInPath;
    },
    primaryButtonText() {
      return this.isLoggedIn ? undefined : __('Register / Sign In');
    },
  },
};
</script>

<template>
  <gl-empty-state
    :title="
      s__(
        'ServiceDesk|Use Service Desk to connect with your users and offer customer support through email right inside GitLab',
      )
    "
    :svg-path="$options.emptyStateSvg"
    :primary-button-text="primaryButtonText"
    :primary-button-link="primaryButtonLink"
    data-testid="issues-service-desk-empty-state"
  >
    <template #description>
      <p v-if="canSeeEmailAddress">
        {{ s__('ServiceDesk|Your users can send emails to this address:') }} <br /><code>{{
          serviceDeskEmailAddress
        }}</code>
      </p>
      <p>
        {{
          s__(
            'ServiceDesk|Tickets created from Service Desk emails will appear here. Each comment becomes part of the email conversation.',
          )
        }}
      </p>
      <gl-link :href="serviceDeskHelpPath">
        {{ __('Learn more about Service Desk') }}
      </gl-link>
    </template>
  </gl-empty-state>
</template>
