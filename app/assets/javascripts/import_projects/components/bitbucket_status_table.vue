<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import ImportProjectsTable from './import_projects_table.vue';

export default {
  components: {
    ImportProjectsTable,
    GlAlert,
    GlSprintf,
    GlLink,
  },
  inheritAttrs: false,
  props: {
    providerTitle: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isWarningDismissed: false,
    };
  },
  computed: {
    currentPage() {
      return window.location.href;
    },
  },
};
</script>
<template>
  <import-projects-table :provider-title="providerTitle" v-bind="$attrs">
    <template #actions>
      <slot name="actions"></slot>
    </template>
    <template #incompatible-repos-warning>
      <gl-alert
        v-if="!isWarningDismissed"
        variant="warning"
        class="gl-my-2"
        @dismiss="isWarningDismissed = true"
      >
        <gl-sprintf
          :message="
            __(
              'One or more of your %{provider} projects cannot be imported into GitLab directly because they use Subversion or Mercurial for version control, rather than Git.',
            )
          "
        >
          <template #provider>
            {{ providerTitle }}
          </template>
        </gl-sprintf>
        <gl-sprintf
          :message="
            __(
              'Please convert %{linkStart}them to Git%{linkEnd}, and go through the %{linkToImportFlow} again.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link
              href="https://www.atlassian.com/git/tutorials/migrating-overview"
              target="_blank"
              >{{ content }}</gl-link
            >
          </template>
          <template #linkToImportFlow>
            <gl-link :href="currentPage">{{ __('import flow') }}</gl-link>
          </template>
        </gl-sprintf>
      </gl-alert>
    </template>
  </import-projects-table>
</template>
