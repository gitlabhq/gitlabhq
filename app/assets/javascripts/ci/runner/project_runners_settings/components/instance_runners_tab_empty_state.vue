<script>
import EMPTY_STATE_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-pipeline-md.svg?url';
import { GlSprintf, GlLink, GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'InstanceRunnersTabEmptyState',
  components: {
    GlSprintf,
    GlLink,
    GlEmptyState,
  },
  props: {
    instanceRunnersEnabled: {
      type: Boolean,
      default: false,
      required: false,
    },
    instanceRunnersDisabledAndUnoverridable: {
      type: Boolean,
      default: false,
      required: false,
    },
    groupName: {
      type: String,
      required: false,
      default: null,
    },
    groupSettingsPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    title() {
      if (this.instanceRunnersEnabled) {
        return s__('Runners|No instance runners found');
      }
      return s__('Runners|Instance runners are turned off');
    },
    isGroupSettingsAvailable() {
      return this.groupSettingsPath && this.groupName;
    },
  },
  EMPTY_STATE_SVG_URL,
};
</script>
<template>
  <gl-empty-state :svg-path="$options.EMPTY_STATE_SVG_URL" :title="title">
    <template #description>
      <div v-if="instanceRunnersEnabled">
        {{ s__('Runners|This instance does not have any instance runners yet.') }}
      </div>
      <div v-else-if="instanceRunnersDisabledAndUnoverridable">
        {{ s__('Runners|Instance runners are turned off in the group settings.') }}
        <gl-sprintf
          v-if="isGroupSettingsAvailable"
          :message="s__('Runners|Go to %{groupLink} to enable them.')"
        >
          <template #groupLink>
            <gl-link :href="groupSettingsPath">{{ groupName }}</gl-link>
          </template>
        </gl-sprintf>
      </div>
      <div v-else>
        {{
          s__('Runners|Instance runners are turned off for this project. Turn them on to use them.')
        }}
      </div>
    </template>
  </gl-empty-state>
</template>
