<script>
import {
  GlAlert,
  GlButton,
  GlFormGroup,
  GlFormRadio,
  GlFormRadioGroup,
  GlLink,
  GlToastMixin,
} from '@gitlab/ui';
import { updateFeatureFlagsSettings } from '~/api/feature_flags_api';
import { helpPagePath } from '~/helpers/help_page_helper';
import { HTTP_STATUS_FORBIDDEN } from '~/lib/utils/http_status';
import { __, s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

export const MINIMUM_ROLE_DEVELOPER = 'developer';
export const MINIMUM_ROLE_MAINTAINER = 'maintainer';
export const MINIMUM_ROLE_NO_ONE = 'no_one_allowed';
export const MINIMUM_ROLE_OWNER = 'owner';

const LOCKED_MESSAGE = s__(
  'FeatureFlags|Only project Owners can change this setting while it is set to Owner or No one.',
);

export default {
  name: 'FeatureFlagsMinimumRole',
  LOCKED_MESSAGE,
  helpPath: helpPagePath('operations/feature_flags', {
    anchor: 'restrict-who-can-manage-feature-flags',
  }),
  ROLE_OPTIONS: [
    {
      text: __('No one'),
      value: MINIMUM_ROLE_NO_ONE,
      help: s__('FeatureFlags|No one can manage feature flags.'),
    },
    {
      text: __('Owner'),
      value: MINIMUM_ROLE_OWNER,
    },
    {
      text: __('Maintainer'),
      value: MINIMUM_ROLE_MAINTAINER,
    },
    {
      text: __('Developer'),
      value: MINIMUM_ROLE_DEVELOPER,
    },
  ],
  components: {
    GlAlert,
    GlButton,
    GlFormGroup,
    GlFormRadio,
    GlFormRadioGroup,
    GlLink,
  },
  mixins: [GlToastMixin],
  inject: ['projectFullPath', 'minimumRole', 'canUpdate'],
  data() {
    return {
      errorMessage: '',
      isSubmitting: false,
      selectedRole: this.minimumRole,
    };
  },
  methods: {
    async updateSetting() {
      this.isSubmitting = true;
      try {
        await updateFeatureFlagsSettings(this.projectFullPath, { minimumRole: this.selectedRole });
        this.errorMessage = '';
        this.$toast.show(s__('FeatureFlags|Minimum role successfully updated.'));
      } catch (error) {
        // A 403 means another Owner tightened the setting since page load. Expected, so
        // swap the bare "403 Forbidden" body for the reason and skip Sentry.
        if (error?.response?.status === HTTP_STATUS_FORBIDDEN) {
          this.errorMessage = LOCKED_MESSAGE;
        } else {
          this.errorMessage =
            error?.response?.data?.message ||
            s__('FeatureFlags|Could not update the minimum role setting.');
          Sentry.captureException(error);
        }
      } finally {
        this.isSubmitting = false;
      }
    },
  },
};
</script>

<template>
  <div class="gl-mb-5">
    <gl-alert v-if="errorMessage" class="gl-mb-5" variant="danger" @dismiss="errorMessage = ''">{{
      errorMessage
    }}</gl-alert>
    <gl-form-group :label="s__('FeatureFlags|Minimum role to manage feature flags')">
      <template #label-description>
        <span>{{
          s__(
            'FeatureFlags|Select the minimum role required to create, update, toggle, or delete feature flags. Members with a lower role can still see feature flags and their status.',
          )
        }}</span>
        <gl-link :href="$options.helpPath" target="_blank">{{ __('Learn more.') }}</gl-link>
      </template>
      <gl-form-radio-group v-model="selectedRole" :disabled="!canUpdate">
        <gl-form-radio v-for="role in $options.ROLE_OPTIONS" :key="role.value" :value="role.value">
          {{ role.text }}
          <template v-if="role.help" #help>{{ role.help }}</template>
        </gl-form-radio>
      </gl-form-radio-group>
      <p v-if="!canUpdate" class="gl-mb-0 gl-mt-3 gl-text-subtle">
        {{ $options.LOCKED_MESSAGE }}
      </p>
      <gl-button
        v-else
        category="primary"
        variant="confirm"
        class="gl-mt-3"
        :loading="isSubmitting"
        @click="updateSetting"
        >{{ __('Save changes') }}
      </gl-button>
    </gl-form-group>
  </div>
</template>
