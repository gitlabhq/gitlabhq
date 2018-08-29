<script>
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
            (Object.prototype.hasOwnProperty.call(value, 'link') &&
              Object.prototype.hasOwnProperty.call(value, 'method') &&
              Object.prototype.hasOwnProperty.call(value, 'title'))
          );
        },
      },
    },
  };
</script>
<template>
  <div class="row empty-state">
    <div class="col-12">
      <div
        :class="illustrationSizeClass"
        class="svg-content"
      >
        <img :src="illustrationPath" />
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
            :href="action.link"
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
