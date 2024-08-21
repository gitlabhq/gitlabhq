<script>
import { GlButton, GlLink, GlSprintf } from '@gitlab/ui';
import { isEqual } from 'lodash';
import {
  PACKAGE_FORWARDING_SECURITY_DESCRIPTION,
  PACKAGE_FORWARDING_SETTINGS_HEADER,
  PACKAGE_FORWARDING_SETTINGS_DESCRIPTION,
  PACKAGE_FORWARDING_FORM_BUTTON,
  PACKAGE_FORWARDING_FIELDS,
  MAVEN_FORWARDING_FIELDS,
  REQUEST_FORWARDING_HELP_PAGE_PATH,
} from '~/packages_and_registries/settings/group/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import updateNamespacePackageSettings from '~/packages_and_registries/settings/group/graphql/mutations/update_group_packages_settings.mutation.graphql';
import { updateGroupPackageSettings } from '~/packages_and_registries/settings/group/graphql/utils/cache_update';
import { updateGroupPackagesSettingsOptimisticResponse } from '~/packages_and_registries/settings/group/graphql/utils/optimistic_responses';

import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';
import ForwardingSettings from '~/packages_and_registries/settings/group/components/forwarding_settings.vue';

export default {
  name: 'PackageForwardingSettings',
  i18n: {
    PACKAGE_FORWARDING_FORM_BUTTON,
    PACKAGE_FORWARDING_SECURITY_DESCRIPTION,
    PACKAGE_FORWARDING_SETTINGS_HEADER,
    PACKAGE_FORWARDING_SETTINGS_DESCRIPTION,
  },
  components: {
    ForwardingSettings,
    GlButton,
    GlLink,
    GlSprintf,
    SettingsSection,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['groupPath'],
  props: {
    forwardSettings: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      mutationLoading: false,
      workingCopy: { ...this.forwardSettings },
    };
  },
  computed: {
    packageForwardingFields() {
      const fields = PACKAGE_FORWARDING_FIELDS;

      if (this.glFeatures.mavenCentralRequestForwarding) {
        return fields.concat(MAVEN_FORWARDING_FIELDS);
      }

      return fields;
    },
    isEdited() {
      return !isEqual(this.forwardSettings, this.workingCopy);
    },
    isDisabled() {
      return !this.isEdited || this.mutationLoading;
    },
    npmMutation() {
      if (this.workingCopy.npmPackageRequestsForwardingLocked) {
        return {};
      }

      return {
        npmPackageRequestsForwarding: this.workingCopy.npmPackageRequestsForwarding,
        lockNpmPackageRequestsForwarding: this.workingCopy.lockNpmPackageRequestsForwarding,
      };
    },
    pypiMutation() {
      if (this.workingCopy.pypiPackageRequestsForwardingLocked) {
        return {};
      }

      return {
        pypiPackageRequestsForwarding: this.workingCopy.pypiPackageRequestsForwarding,
        lockPypiPackageRequestsForwarding: this.workingCopy.lockPypiPackageRequestsForwarding,
      };
    },
    mavenMutation() {
      if (this.workingCopy.mavenPackageRequestsForwardingLocked) {
        return {};
      }

      return {
        mavenPackageRequestsForwarding: this.workingCopy.mavenPackageRequestsForwarding,
        lockMavenPackageRequestsForwarding: this.workingCopy.lockMavenPackageRequestsForwarding,
      };
    },
    mutationVariables() {
      return {
        ...this.npmMutation,
        ...this.pypiMutation,
        ...this.mavenMutation,
      };
    },
  },
  watch: {
    forwardSettings(newValue) {
      this.workingCopy = { ...newValue };
    },
  },
  methods: {
    isForwardingFieldsDisabled(fields) {
      const isLocked = fields?.modelNames?.isLocked;

      return this.mutationLoading || this.workingCopy[isLocked];
    },
    forwardingFieldsForwarding(fields) {
      const forwarding = fields?.modelNames?.forwarding;

      return this.workingCopy[forwarding];
    },
    forwardingFieldsLockForwarding(fields) {
      const lockForwarding = fields?.modelNames?.lockForwarding;

      return this.workingCopy[lockForwarding];
    },
    async submit() {
      this.mutationLoading = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: updateNamespacePackageSettings,
          variables: {
            input: {
              namespacePath: this.groupPath,
              ...this.mutationVariables,
            },
          },
          update: updateGroupPackageSettings(this.groupPath),
          optimisticResponse: updateGroupPackagesSettingsOptimisticResponse({
            ...this.forwardSettings,
            ...this.mutationVariables,
          }),
        });

        if (data.updateNamespacePackageSettings?.errors?.length > 0) {
          throw new Error();
        } else {
          this.$emit('success');
        }
      } catch {
        this.$emit('error');
      } finally {
        this.mutationLoading = false;
      }
    },
    updateWorkingCopy(type, value) {
      this.workingCopy = {
        ...this.workingCopy,
        [type]: value,
      };
    },
  },
  links: {
    REQUEST_FORWARDING_HELP_PAGE_PATH,
  },
};
</script>

<template>
  <settings-section :heading="$options.i18n.PACKAGE_FORWARDING_SETTINGS_HEADER">
    <template #description>
      <span class="gl-mb-2 gl-block" data-testid="description">
        {{ $options.i18n.PACKAGE_FORWARDING_SETTINGS_DESCRIPTION }}
      </span>
      <gl-sprintf :message="$options.i18n.PACKAGE_FORWARDING_SECURITY_DESCRIPTION">
        <template #docLink="{ content }">
          <gl-link :href="$options.links.REQUEST_FORWARDING_HELP_PAGE_PATH">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>

    <form @submit.prevent="submit">
      <forwarding-settings
        v-for="forwardingFields in packageForwardingFields"
        :key="forwardingFields.label"
        :data-testid="forwardingFields.testid"
        :disabled="isForwardingFieldsDisabled(forwardingFields)"
        :forwarding="forwardingFieldsForwarding(forwardingFields)"
        :label="forwardingFields.label"
        :lock-forwarding="forwardingFieldsLockForwarding(forwardingFields)"
        :model-names="forwardingFields.modelNames"
        @update="updateWorkingCopy"
      />
      <gl-button
        type="submit"
        :disabled="isDisabled"
        :loading="mutationLoading"
        category="primary"
        variant="confirm"
        class="js-no-auto-disable gl-mr-4"
      >
        {{ $options.i18n.PACKAGE_FORWARDING_FORM_BUTTON }}
      </gl-button>
    </form>
  </settings-section>
</template>
