<script>
import { GlButton, GlCard, GlIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import { RESOURCE_TYPES } from '~/groups_projects/constants';
import { archiveGroup } from '~/api/groups_api';
import { archiveProject } from '~/api/projects_api';
import { InternalEvents } from '~/tracking';

export default {
  name: 'ArchiveSettings',
  components: {
    GlCard,
    GlLink,
    GlButton,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin()],
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
    markedForDeletion: {
      type: Boolean,
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
      disabledTooltip: s__(
        'GroupProjectArchiveSettings|To archive this group, you must restore it from deletion.',
      ),
      description: s__(
        'GroupProjectArchiveSettings|Make your group read-only. You can still access its data, work items, and merge requests.',
      ),
      helpLink: s__('GroupProjectArchiveSettings|How do I archive a group?'),
      error: s__(
        'GroupProjectArchiveSettings|An error occurred while archiving the group. Please refresh the page and try again.',
      ),
    },
    [RESOURCE_TYPES.PROJECT]: {
      header: s__('GroupProjectArchiveSettings|Archive project'),
      disabledTooltip: s__(
        'GroupProjectArchiveSettings|To archive this project, you must restore it from deletion.',
      ),
      description: s__(
        'GroupProjectArchiveSettings|Make your project read-only. You can still access its data, work items, and merge requests.',
      ),
      helpLink: s__('GroupProjectArchiveSettings|How do I archive a project?'),
      error: s__(
        'GroupProjectArchiveSettings|An error occurred while archiving the project. Please refresh the page and try again.',
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
      <h4 class="gl-m-0 gl-flex gl-items-center gl-gap-3 gl-text-base">
        {{ i18n.header }}
        <gl-icon
          v-if="markedForDeletion"
          v-gl-tooltip="i18n.disabledTooltip"
          :aria-label="i18n.disabledTooltip"
          :size="16"
          name="cancel"
          class="gl-cursor-pointer"
        />
      </h4>
    </template>
    <template #default>
      <p class="gl-mb-0">
        {{ i18n.description }}
        <gl-link v-if="helpPath" :href="helpPath" target="_blank">
          {{ i18n.helpLink }}
        </gl-link>
      </p>
      <gl-button
        v-if="!markedForDeletion"
        data-testid="archive-button"
        data-event-tracking="archive_namespace_in_settings"
        data-event-property="archive"
        class="gl-mt-5"
        :data-event-label="resourceType"
        :loading="loading"
        @click="archive"
      >
        {{ s__('GroupProjectArchiveSettings|Archive') }}
      </gl-button>
    </template>
  </gl-card>
</template>
