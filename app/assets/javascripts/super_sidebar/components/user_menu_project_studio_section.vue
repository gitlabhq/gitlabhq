<script>
import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem, GlIcon, GlToggle } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import { createAlert } from '~/alert';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__, __ } from '~/locale';
import setProjectStudioEnabled from '../graphql/queries/set_project_studio_enabled.mutation.graphql';

export default {
  i18n: {},
  components: {
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    GlIcon,
    GlToggle,
  },
  mixins: [InternalEvents.mixin()],
  inject: ['isImpersonating', 'projectStudioEnabled'],
  data() {
    return {
      loading: false,
    };
  },
  computed: {
    toggleProjectStudioItem() {
      return {
        text: s__('Navigation|Preview new UI'),
        action: () => {
          this.toggleSetting(!this.projectStudioEnabled);
        },
        extraAttrs: {
          'data-testid': 'toggle-project-studio-link',
        },
      };
    },
    provideProjectStudioFeedbackItem() {
      return {
        href: 'https://gitlab.com/gitlab-org/gitlab/-/issues/577554',
        text: s__('Navigation|Provide feedback'),
        extraAttrs: {
          'data-testid': 'project-studio-feedback-link',
        },
      };
    },
  },
  methods: {
    toggleSetting(val) {
      this.loading = true;

      // Track the opt-in or opt-out event
      const eventName = val ? 'opt_in_project_studio' : 'opt_out_project_studio';
      this.trackEvent(eventName);

      this.$apollo
        .mutate({
          mutation: setProjectStudioEnabled,
          variables: {
            projectStudioEnabled: val,
          },
          update: () => {
            // If user is enabling the New UI (val=true and currently disabled), flag for onboarding
            if (val === true && this.projectStudioEnabled === false) {
              localStorage.setItem('showDapWelcomeModal', 'true');
            }
            window.location.reload();
          },
        })
        .catch((error) => {
          this.loading = false;
          createAlert({
            message: __('Something went wrong. Please try again.'),
          });
          Sentry.captureException(error);
        });
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-group bordered>
    <gl-disclosure-dropdown-item :item="toggleProjectStudioItem">
      <template #list-item>
        <div class="gl-flex gl-items-center gl-gap-3">
          <gl-icon name="template" variant="subtle" />
          <div class="gl-grow">{{ s__('Navigation|New UI') }}</div>
          <gl-toggle
            :label="
              projectStudioEnabled
                ? __('Opt out of Project Studio')
                : __('Opt in to Project Studio')
            "
            label-position="hidden"
            :value="projectStudioEnabled"
            :is-loading="loading"
          />
        </div>
      </template>
    </gl-disclosure-dropdown-item>
    <gl-disclosure-dropdown-item :item="provideProjectStudioFeedbackItem">
      <template #list-item>
        <gl-icon name="comment-dots" variant="subtle" class="gl-mr-2" />
        {{ s__('Navigation|Provide feedback') }}
      </template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown-group>
</template>
