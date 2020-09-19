<script>
/* eslint-disable vue/no-v-html */
import { GlPopover } from '@gitlab/ui';
import Tracking from '~/tracking';
import LegacyContainer from './legacy_container.vue';

const trackingMixin = Tracking.mixin(gon.tracking_data);

export default {
  components: {
    GlPopover,
    LegacyContainer,
  },
  mixins: [trackingMixin],
  props: {
    panels: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <div class="container">
    <div class="blank-state-welcome">
      <h2 class="blank-state-welcome-title gl-mt-5! gl-mb-3!">
        {{ s__('ProjectsNew|Create new project') }}
      </h2>
      <p div class="blank-state-text">&nbsp;</p>
    </div>
    <div class="row blank-state-row">
      <a
        v-for="panel in panels"
        :key="panel.name"
        :href="`#${panel.name}`"
        :data-qa-selector="`${panel.name}_link`"
        class="blank-state blank-state-link experiment-new-project-page-blank-state"
        @click="track('click_tab', { label: panel.name })"
      >
        <div class="blank-state-icon" v-html="panel.illustration"></div>
        <div class="blank-state-body gl-pl-4!">
          <h3 class="blank-state-title experiment-new-project-page-blank-state-title">
            {{ panel.title }}
          </h3>
          <p class="blank-state-text">
            {{ panel.description }}
          </p>
        </div>
      </a>
    </div>
    <div class="blank-state-welcome">
      <p>
        {{ __('You can also create a project from the command line.') }}
        <a
          id="cli-tip"
          href="#"
          click.prevent
          class="push-new-project-tip"
          data-title="Push to create a project"
          rel="noopener noreferrer"
        >
          {{ __('Show command') }}
        </a>

        <gl-popover target="cli-tip" triggers="click blur" placement="top">
          <legacy-container selector=".push-new-project-tip-template" />
        </gl-popover>
      </p>
    </div>
  </div>
</template>
