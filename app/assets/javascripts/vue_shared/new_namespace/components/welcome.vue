<!-- eslint-disable vue/multi-word-component-names -->
<script>
import Tracking from '~/tracking';

export default {
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
  <div class="gl-flex gl-flex-col">
    <h2 class="gl-my-7 gl-text-center gl-text-size-h1">
      {{ title }}
    </h2>
    <div>
      <div
        v-for="panel in panels"
        :key="panel.name"
        class="new-namespace-panel-wrapper gl-float-left gl-mb-5 gl-inline-block gl-px-3"
      >
        <a
          :href="`#${panel.name}`"
          data-testid="panel-link"
          :data-qa-panel-name="panel.name"
          class="new-namespace-panel gl-flex gl-w-full gl-shrink-0 gl-flex-col gl-items-center gl-rounded-base gl-border-1 gl-border-solid gl-border-default gl-px-3 gl-py-6 hover:!gl-no-underline lg:gl-flex-row"
          @click="track('click_tab', { label: panel.name })"
        >
          <div class="new-namespace-panel-illustration gl-flex gl-shrink-0 gl-justify-center">
            <img aria-hidden="true" :src="panel.imageSrc" :alt="panel.title" />
          </div>
          <div class="gl-pl-4">
            <h3 class="gl-text-color-heading gl-text-size-h2">
              {{ panel.title }}
            </h3>
            <p class="gl-text-default">
              {{ panel.description }}
            </p>
          </div>
        </a>
      </div>
    </div>
    <slot name="footer"></slot>
  </div>
</template>
