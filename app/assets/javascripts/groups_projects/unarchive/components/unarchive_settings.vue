<script>
import { GlButton, GlCard, GlIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import { RESOURCE_TYPES } from '~/groups_projects/constants';
import { unarchiveGroup } from '~/api/groups_api';
import { unarchiveProject } from '~/api/projects_api';
import { InternalEvents } from '~/tracking';

export default {
  components: {
    GlCard,
    GlButton,
    GlIcon,
    GlLink,
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
    ancestorsArchived: {
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
      header: s__('GroupProjectUnarchiveSettings|Unarchive group'),
      disabledTooltip: s__(
        'GroupProjectUnarchiveSettings|To unarchive this group, you must unarchive its parent group.',
      ),
      description: s__(
        "GroupProjectUnarchiveSettings|Restore your group to an active state. You'll be able to modify its content and settings again.",
      ),
      error: s__(
        'GroupProjectUnarchiveSettings|An error occurred while unarchiving the group. Please refresh the page and try again.',
      ),
      helpLink: s__('GroupProjectUnarchiveSettings|How do I unarchive a group?'),
    },
    [RESOURCE_TYPES.PROJECT]: {
      header: s__('GroupProjectUnarchiveSettings|Unarchive project'),
      disabledTooltip: s__(
        'GroupProjectUnarchiveSettings|To unarchive this project, you must unarchive its parent group.',
      ),
      description: s__(
        "GroupProjectUnarchiveSettings|Restore your project to an active state. You'll be able to modify its content and settings again.",
      ),
      error: s__(
        'GroupProjectUnarchiveSettings|An error occurred while unarchiving the project. Please refresh the page and try again.',
      ),
      helpLink: s__('GroupProjectUnarchiveSettings|How do I unarchive a project?'),
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
    unarchiveResource() {
      return this.resourceType === RESOURCE_TYPES.GROUP ? unarchiveGroup : unarchiveProject;
    },
  },
  methods: {
    async unarchive() {
      this.loading = true;

      try {
        await this.unarchiveResource(this.resourceId);
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
          v-if="ancestorsArchived"
          v-gl-tooltip="i18n.disabledTooltip"
          name="cancel"
          class="gl-cursor-pointer"
          :size="16"
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
        v-if="!ancestorsArchived"
        data-testid="unarchive-button"
        data-event-tracking="archive_namespace_in_settings"
        data-event-property="unarchive"
        :data-event-label="resourceType"
        class="gl-mt-5"
        :loading="loading"
        @click="unarchive"
      >
        {{ s__('GroupProjectUnarchiveSettings|Unarchive') }}
      </gl-button>
    </template>
  </gl-card>
</template>
