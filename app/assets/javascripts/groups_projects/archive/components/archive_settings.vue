<script>
import { GlButton, GlCard, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import { RESOURCE_TYPES } from '~/groups_projects/constants';
import { archiveGroup } from '~/api/groups_api';
import { archiveProject } from '~/api/projects_api';

export default {
  name: 'ArchiveSettings',
  components: {
    GlCard,
    GlLink,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    resourceType: {
      type: String,
      required: true,
      validator: (value) => Object.values(RESOURCE_TYPES).includes(value),
    },
    resourceId: {
      type: String,
      required: true,
    },
    resourcePath: {
      type: String,
      required: true,
    },
    helpPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  resourceStrings: {
    [RESOURCE_TYPES.GROUP]: {
      header: s__('GroupProjectArchiveSettings|Archive group'),
      description: s__(
        'GroupProjectArchiveSettings|Make your group read-only while preserving all data and access to its repository, issues, and merge requests.',
      ),
      helpLink: s__('GroupProjectArchiveSettings|How do I archive a group?'),
      error: s__(
        'GroupProjectArchiveSettings|An error occurred while archiving the group. Please refresh the page an try again.',
      ),
    },
    [RESOURCE_TYPES.PROJECT]: {
      header: s__('GroupProjectArchiveSettings|Archive project'),
      description: s__(
        'GroupProjectArchiveSettings|Make your project read-only while preserving all data and access to its repository, issues, and merge requests.',
      ),
      helpLink: s__('GroupProjectArchiveSettings|How do I archive a project?'),
      error: s__(
        'GroupProjectArchiveSettings|An error occurred while archiving the project. Please refresh the page an try again.',
      ),
    },
  },
  data() {
    return {
      loading: false,
    };
  },
  computed: {
    i18n() {
      return this.$options.resourceStrings[this.resourceType];
    },
    archiveResource() {
      return this.resourceType === RESOURCE_TYPES.GROUP ? archiveGroup : archiveProject;
    },
  },
  methods: {
    async archive() {
      this.loading = true;

      try {
        await this.archiveResource(this.resourceId);
        visitUrl(this.resourcePath);
      } catch (error) {
        createAlert({ message: this.i18n.error, error, captureError: true });
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <gl-card>
    <template #header>
      <h4 class="gl-m-0 gl-text-base">{{ i18n.header }}</h4>
    </template>
    <template #default>
      <p>
        {{ i18n.description }}
        <gl-link v-if="helpPath" :href="helpPath" target="_blank">
          {{ i18n.helpLink }}
        </gl-link>
      </p>
      <gl-button :loading="loading" @click="archive">
        {{ s__('GroupProjectArchiveSettings|Archive') }}
      </gl-button>
    </template>
  </gl-card>
</template>
