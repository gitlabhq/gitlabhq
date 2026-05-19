<script>
import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import organizationsEmptyStateSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-organizations-md.svg?url';
import { s__, sprintf } from '~/locale';
import { artifactRegistryOrganizationIndexPath } from '~/lib/utils/path_helpers/organizations';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';

export default {
  name: 'OrganizationShowApp',
  components: { GlEmptyState, GlLink, GlSprintf, HelpPageLink },
  organizationsEmptyStateSvgPath,
  props: {
    organization: {
      type: Object,
      required: true,
    },
    canReadArtifactRegistry: {
      type: Boolean,
      required: true,
    },
    canAdminOrganization: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    emptyStateTitle() {
      return sprintf(s__('Organization|Welcome to %{organizationName}'), {
        organizationName: this.organization.name,
      });
    },
    emptyStateDescription() {
      if (this.canReadArtifactRegistry && this.canAdminOrganization) {
        return s__(
          "Organization|%{organizationName} is your organization's home. Manage Artifact Registry and settings from the sidebar. %{linkStart}Learn more%{linkEnd}.",
        );
      }

      if (this.canReadArtifactRegistry) {
        return s__(
          "Organization|%{organizationName} is your organization's home. Manage Artifact Registry from the sidebar. %{linkStart}Learn more%{linkEnd}.",
        );
      }

      if (this.canAdminOrganization) {
        return s__(
          "Organization|%{organizationName} is your organization's home. Manage settings from the sidebar. %{linkStart}Learn more%{linkEnd}.",
        );
      }

      return s__(
        "Organization|%{organizationName} is your organization's home. %{linkStart}Learn more%{linkEnd}.",
      );
    },
  },
  methods: {
    artifactRegistryOrganizationIndexPath,
  },
};
</script>

<template>
  <div class="gl-py-6">
    <gl-empty-state
      :title="emptyStateTitle"
      :svg-path="$options.organizationsEmptyStateSvgPath"
      :header-level="1"
    >
      <template #description>
        <gl-sprintf :message="emptyStateDescription">
          <template #organizationName>{{ organization.name }}</template>
          <template #link="{ content }">
            <help-page-link href="/user/organization/_index.md">{{ content }}</help-page-link>
          </template>
        </gl-sprintf>
      </template>
      <template v-if="canReadArtifactRegistry" #actions>
        <gl-link :href="artifactRegistryOrganizationIndexPath(organization.path)">{{
          s__('Organization|Go to Artifact Registry')
        }}</gl-link>
      </template>
    </gl-empty-state>
  </div>
</template>
