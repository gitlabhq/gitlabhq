<script>
import SafeHtml from '~/vue_shared/directives/safe_html';
import Tracking from '~/tracking';

export default {
  directives: {
    SafeHtml,
  },
  mixins: [Tracking.mixin()],
  props: {
    title: {
      type: String,
      required: true,
    },
    panels: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <div class="gl-display-flex gl-flex-direction-column">
    <h2 class="gl-my-7 gl-font-size-h1 gl-text-center">
      {{ title }}
    </h2>
    <div>
      <div
        v-for="panel in panels"
        :key="panel.name"
        class="new-namespace-panel-wrapper gl-display-inline-block gl-float-left gl-px-3 gl-mb-5"
      >
        <a
          :href="`#${panel.name}`"
          data-qa-selector="panel_link"
          :data-qa-panel-name="panel.name"
          class="new-namespace-panel gl-display-flex gl-flex-shrink-0 gl-flex-direction-column gl-lg-flex-direction-row gl-align-items-center gl-rounded-base gl-border-gray-100 gl-border-solid gl-border-1 gl-w-full gl-py-6 gl-px-3 gl-hover-text-decoration-none!"
          @click="track('click_tab', { label: panel.name })"
        >
          <div
            v-safe-html="panel.illustration"
            class="new-namespace-panel-illustration gl-text-white gl-display-flex gl-flex-shrink-0 gl-justify-content-center"
          ></div>
          <div class="gl-pl-4">
            <h3 class="gl-font-size-h2 gl-reset-color">
              {{ panel.title }}
            </h3>
            <p class="gl-text-gray-900">
              {{ panel.description }}
            </p>
          </div>
        </a>
      </div>
    </div>
    <slot name="footer"></slot>
  </div>
</template>
