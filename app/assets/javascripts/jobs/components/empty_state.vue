<script>
import { placeholderImage } from '~/lazy_loader';
  export default {
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
              Object.prototype.hasOwnProperty.call(value, 'title'))
          );
        },
      },
    },
    placeholderImage: placeholderImage,
  };
</script>
<template>
  <div class="row empty-state">
    <div class="col-12">
      <div
        :class="illustrationSizeClass"
        class="svg-content"
      >
        <img
          :data-src="illustrationPath"
          class="lazy"
          :src="$options.placeholderImage"
        />

      </div>
    </div>

    <div class="col-12">
      <div class="text-content">
        <h4 class="js-job-empty-state-title text-center">
          {{ title }}
        </h4>

        <p
          v-if="content"
          class="js-job-empty-state-content"
        >
          {{ content }}
        </p>

        <div
          v-if="action"
          class="text-center"
        >
          <a
            :href="action.path"
            :data-method="action.method"
            class="js-job-empty-state-action btn btn-primary"
          >
            {{ action.title }}
          </a>
        </div>
      </div>
    </div>
  </div>
</template>
