<script>
import EMPTY_STATE_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-pipeline-md.svg?url';
import { GlSprintf, GlLink, GlEmptyState } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'GroupRunnersTabEmptyState',
  components: {
    GlSprintf,
    GlLink,
    GlEmptyState,
  },
  inject: {
    canCreateRunnerForGroup: {
      default: false,
    },
    groupRunnersPath: {
      default: null,
    },
  },
  props: {
    groupRunnersEnabled: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    title() {
      if (this.groupRunnersEnabled) {
        return s__('Runners|No group runners found');
      }
      return s__('Runners|Group runners are turned off');
    },
  },
  EMPTY_STATE_SVG_URL,
};
</script>
<template>
  <gl-empty-state :svg-path="$options.EMPTY_STATE_SVG_URL" :title="title">
    <template #description>
      <div v-if="groupRunnersEnabled">
        {{ __('This group does not have any group runners yet.') }}
        <template v-if="canCreateRunnerForGroup">
          <gl-sprintf
            :message="
              s__(
                'Runners|To register them, go to the %{linkStart}group\'s Runners page%{linkEnd}.',
              )
            "
          >
            <template #link="{ content }">
              <gl-link v-if="groupRunnersPath" :href="groupRunnersPath">{{ content }}</gl-link>
              <span v-else>{{ content }}</span>
            </template>
          </gl-sprintf>
        </template>
        <template v-else>
          {{ __('Ask your group owner to set up a group runner.') }}
        </template>
      </div>
      <div v-else>
        {{
          s__('Runners|Group runners are turned off for this project. Turn them on to use them.')
        }}
      </div>
    </template>
  </gl-empty-state>
</template>
