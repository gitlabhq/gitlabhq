<script>
import { GlLink } from '@gitlab/ui';

export default {
  components: {
    GlLink,
  },
  props: {
    illustrationPath: {
      type: String,
      required: true,
    },
    illustrationSizeClass: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    content: {
      type: String,
      required: false,
      default: null,
    },
    action: {
      type: Object,
      required: false,
      default: null,
      validator(value) {
        return (
          value === null ||
          (Object.prototype.hasOwnProperty.call(value, 'path') &&
            Object.prototype.hasOwnProperty.call(value, 'method') &&
            Object.prototype.hasOwnProperty.call(value, 'button_title'))
        );
      },
    },
  },
};
</script>
<template>
  <div class="row empty-state">
    <div class="col-12">
      <div :class="illustrationSizeClass" class="svg-content"><img :src="illustrationPath" /></div>
    </div>

    <div class="col-12">
      <div class="text-content">
        <h4 class="js-job-empty-state-title text-center">{{ title }}</h4>

        <p v-if="content" class="js-job-empty-state-content text-center">{{ content }}</p>

        <div v-if="action" class="text-center">
          <gl-link
            :href="action.path"
            :data-method="action.method"
            class="js-job-empty-state-action btn btn-primary"
          >
            {{ action.button_title }}
          </gl-link>
        </div>
      </div>
    </div>
  </div>
</template>
