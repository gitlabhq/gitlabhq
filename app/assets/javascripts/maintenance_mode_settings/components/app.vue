<script>
import { GlToggle, GlFormGroup, GlFormTextarea, GlButton } from '@gitlab/ui';

export default {
  name: 'MaintenanceModeSettingsApp',
  components: {
    GlToggle,
    GlFormGroup,
    GlFormTextarea,
    GlButton,
  },
  data() {
    return {
      inMaintenanceMode: false,
      bannerMessage: '',
    };
  },
};
</script>
<template>
  <article>
    <div class="d-flex align-items-center mb-3">
      <gl-toggle v-model="inMaintenanceMode" class="mb-0" />
      <div class="ml-2">
        <p class="mb-0">{{ __('Enable maintenance mode') }}</p>
        <p class="mb-0 text-secondary-500">
          {{
            __('Non-admin users can sign in with read-only access and make read-only API requests.')
          }}
        </p>
      </div>
    </div>
    <gl-form-group label="Banner Message" label-for="maintenanceBannerMessage">
      <gl-form-textarea
        id="maintenanceBannerMessage"
        v-model="bannerMessage"
        :placeholder="__(`GitLab is undergoing maintenance and is operating in a read-only mode.`)"
      />
    </gl-form-group>
    <div class="mt-4">
      <gl-button variant="success" category="primary">{{ __('Save changes') }}</gl-button>
    </div>
  </article>
</template>
