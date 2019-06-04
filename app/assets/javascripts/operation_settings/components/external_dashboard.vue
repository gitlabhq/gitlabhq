<script>
import { GlButton, GlFormGroup, GlFormInput, GlLink } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlLink,
  },
  props: {
    externalDashboardPath: {
      type: String,
      required: false,
      default: '',
    },
    externalDashboardHelpPagePath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <section class="settings no-animate">
    <div class="settings-header">
      <h4 class="js-section-header">
        {{ s__('ExternalMetrics|External Dashboard') }}
      </h4>
      <gl-button class="js-settings-toggle">{{ __('Expand') }}</gl-button>
      <p class="js-section-sub-header">
        {{
          s__(
            'ExternalMetrics|Add a button to the metrics dashboard linking directly to your existing external dashboards.',
          )
        }}
        <gl-link :href="externalDashboardHelpPagePath">{{ __('Learn more') }}</gl-link>
      </p>
    </div>
    <div class="settings-content">
      <form>
        <gl-form-group
          :label="s__('ExternalMetrics|Full dashboard URL')"
          :description="s__('ExternalMetrics|Enter the URL of the dashboard you want to link to')"
        >
          <gl-form-input
            :value="externalDashboardPath"
            placeholder="https://my-org.gitlab.io/my-dashboards"
          />
        </gl-form-group>
        <gl-button variant="success">
          {{ __('Save Changes') }}
        </gl-button>
      </form>
    </div>
  </section>
</template>
