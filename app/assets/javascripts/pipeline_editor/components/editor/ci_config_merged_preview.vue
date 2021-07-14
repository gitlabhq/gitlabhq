<script>
import { GlAlert, GlLink, GlSprintf, GlIcon } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import SourceEditor from '~/vue_shared/components/source_editor.vue';
import getCurrentBranch from '../../graphql/queries/client/current_branch.graphql';

export default {
  i18n: {
    viewOnlyMessage: s__('Pipelines|Merged YAML is view only'),
    unavailableDefaultTitle: s__('Pipelines|Merged YAML unavailable'),
    unavailableDefaultText: s__(
      'Pipelines|The merged YAML view is only available for the default branch. %{linkStart}Learn more.%{linkEnd}',
    ),
  },
  components: {
    SourceEditor,
    GlAlert,
    GlIcon,
    GlLink,
    GlSprintf,
  },
  inject: ['ciConfigPath', 'defaultBranch'],
  props: {
    ciConfigData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      failureType: null,
    };
  },
  // This is not the best practice, don't copy me (@samdbeckham)
  // This is a temporary workaround to unblock a release.
  // See this comment for more information on this approach
  // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/65972#note_626095648
  apollo: {
    currentBranch: {
      query: getCurrentBranch,
    },
  },
  computed: {
    fileGlobalId() {
      return `${this.ciConfigPath}-${uniqueId()}`;
    },
    mergedYaml() {
      return this.ciConfigData.mergedYaml;
    },
    isOnDefaultBranch() {
      return this.currentBranch === this.defaultBranch;
    },
    expandedConfigHelpPath() {
      return helpPagePath('ci/pipeline_editor/index', { anchor: 'view-expanded-configuration' });
    },
  },
};
</script>
<template>
  <div>
    <div v-if="isOnDefaultBranch">
      <div class="gl-display-flex gl-align-items-center">
        <gl-icon :size="16" name="lock" class="gl-text-gray-500 gl-mr-3" />
        {{ $options.i18n.viewOnlyMessage }}
      </div>
      <div class="gl-mt-3 gl-border-solid gl-border-gray-100 gl-border-1">
        <source-editor
          ref="editor"
          :value="mergedYaml"
          :file-name="ciConfigPath"
          :file-global-id="fileGlobalId"
          :editor-options="{ readOnly: true }"
          v-on="$listeners"
        />
      </div>
    </div>
    <gl-alert
      v-else
      variant="info"
      :dismissible="false"
      :title="$options.i18n.unavailableDefaultTitle"
    >
      <gl-sprintf :message="$options.i18n.unavailableDefaultText">
        <template #link="{ content }">
          <gl-link :href="expandedConfigHelpPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
  </div>
</template>
