<script>
import { GlTable, GlLink, GlSprintf, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { containerRegistryPopover } from '~/usage_quotas/storage/constants';
import NumberToHumanSize from '~/vue_shared/components/number_to_human_size/number_to_human_size.vue';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import StorageTypeHelpLink from './storage_type_help_link.vue';
import StorageTypeWarning from './storage_type_warning.vue';

export default {
  name: 'ProjectList',
  components: {
    GlTable,
    GlLink,
    GlSprintf,
    GlIcon,
    ProjectAvatar,
    NumberToHumanSize,
    HelpPageLink,
    StorageTypeHelpLink,
    StorageTypeWarning,
  },
  props: {
    projects: {
      type: Array,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    helpLinks: {
      type: Object,
      required: true,
    },
    sortBy: {
      type: String,
      required: false,
      default: null,
    },
    sortableFields: {
      type: Object,
      required: true,
      default: null,
    },
  },
  created() {
    this.fields = [
      { key: 'name', label: __('Project') },
      { key: 'storage', label: __('Total'), sortable: this.sortableFields.storage },
      { key: 'repository', label: __('Repository') },
      { key: 'snippets', label: __('Snippets') },
      { key: 'buildArtifacts', label: __('Jobs') },
      { key: 'lfsObjects', label: __('LFS') },
      { key: 'packages', label: __('Packages') },
      { key: 'wiki', label: __('Wiki') },
      {
        key: 'containerRegistry',
        label: __('Containers'),
        thClass: 'gl-border-l!',
        tdClass: 'gl-border-l!',
      },
    ].map((f) => ({
      ...f,
      // eslint-disable-next-line @gitlab/require-i18n-strings
      thClass: `${f.thClass ?? ''} gl-px-3!`,
      // eslint-disable-next-line @gitlab/require-i18n-strings
      tdClass: `${f.tdClass ?? ''} gl-px-3!`,
    }));
  },
  methods: {
    /**
     * Builds a gl-table td cell slot name for particular field
     * @param {string} key
     * @returns {string} */
    getHeaderSlotName(key) {
      return `head(${key})`;
    },
    getUsageQuotasUrl(projectUrl) {
      return `${projectUrl}/-/usage_quotas`;
    },
    /**
     * Creates a relative path from a full project path.
     * E.g. input `namespace / subgroup / project`
     * results in `subgroup / project`
     */
    getProjectRelativePath(fullPath) {
      return fullPath.replace(/.*?\s?\/\s?/, '');
    },
    isCostFactored(project) {
      if (project.statistics.costFactoredStorageSize === undefined) {
        return false;
      }

      return project.statistics.storageSize !== project.statistics.costFactoredStorageSize;
    },
  },
  containerRegistryPopover,
};
</script>

<template>
  <gl-table
    :fields="fields"
    :items="projects"
    :busy="isLoading"
    show-empty
    :empty-text="s__('UsageQuota|No projects to display.')"
    small
    stacked="lg"
    :sort-by="sortBy"
    sort-desc
    no-local-sorting
    no-sort-reset
    @sort-changed="$emit('sortChanged', $event)"
  >
    <template v-for="field in fields" #[getHeaderSlotName(field.key)]>
      <div :key="field.key" :data-testid="'th-' + field.key">
        {{ field.label }}

        <storage-type-help-link
          v-if="field.key in helpLinks"
          :storage-type="field.key"
          :help-links="helpLinks"
        /><storage-type-warning v-if="field.key == 'containerRegistry'">
          {{ $options.containerRegistryPopover.content }}
          <gl-link :href="$options.containerRegistryPopover.docsLink" target="_blank">
            {{ __('Learn more.') }}
          </gl-link>
        </storage-type-warning>
      </div>
    </template>

    <template #cell(name)="{ item: project }">
      <project-avatar
        :project-id="project.id"
        :project-name="project.name"
        :project-avatar-url="project.avatarUrl"
        :size="16"
        :alt="project.name"
        class="gl-display-inline-block gl-mr-2 gl-text-center!"
      />

      <gl-link
        :href="getUsageQuotasUrl(project.webUrl)"
        class="gl-text-gray-900! js-project-link gl-word-break-word"
        data-testid="project-link"
      >
        {{ getProjectRelativePath(project.nameWithNamespace) }}
      </gl-link>
    </template>

    <template #cell(storage)="{ item: project }">
      <template v-if="isCostFactored(project)">
        <number-to-human-size :value="project.statistics.costFactoredStorageSize" />

        <div class="gl-text-gray-600 gl-mt-2 gl-font-sm">
          <gl-sprintf :message="s__('UsageQuotas|(of %{totalStorageSize})')">
            <template #totalStorageSize>
              <number-to-human-size :value="project.statistics.storageSize" />
            </template>
          </gl-sprintf>
          <help-page-link href="user/usage_quotas#view-project-fork-storage-usage" target="_blank">
            <gl-icon name="question-o" :size="12" />
          </help-page-link>
        </div>
      </template>
      <template v-else>
        <number-to-human-size :value="project.statistics.storageSize" />
      </template>
    </template>

    <template #cell(repository)="{ item: project }">
      <number-to-human-size
        :value="project.statistics.repositorySize"
        data-testid="project-repository-size"
      />
    </template>

    <template #cell(lfsObjects)="{ item: project }">
      <number-to-human-size :value="project.statistics.lfsObjectsSize" />
    </template>

    <template #cell(buildArtifacts)="{ item: project }">
      <number-to-human-size :value="project.statistics.buildArtifactsSize" />
    </template>

    <template #cell(packages)="{ item: project }">
      <number-to-human-size :value="project.statistics.packagesSize" />
    </template>

    <template #cell(wiki)="{ item: project }">
      <number-to-human-size :value="project.statistics.wikiSize" data-testid="project-wiki-size" />
    </template>

    <template #cell(snippets)="{ item: project }">
      <number-to-human-size
        :value="project.statistics.snippetsSize"
        data-testid="project-snippets-size"
      />
    </template>

    <template #cell(containerRegistry)="{ item: project }">
      <number-to-human-size
        :value="project.statistics.containerRegistrySize"
        data-testid="project-containers-registry-size"
      />
    </template>
  </gl-table>
</template>
