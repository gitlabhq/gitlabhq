<script>
/* eslint-disable @gitlab/vue-require-i18n-strings */
export default {
  props: {
    total: {
      type: String,
      required: true,
    },
    visible: {
      type: Number,
      required: true,
    },
    plainDiffPath: {
      type: String,
      required: true,
    },
    emailPatchPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="alert alert-warning">
    <h4>
      {{ __('Too many changes to show.') }}
      <div class="float-right">
        <a :href="plainDiffPath" class="btn btn-sm"> {{ __('Plain diff') }} </a>
        <a :href="emailPatchPath" class="btn btn-sm"> {{ __('Email patch') }} </a>
      </div>
    </h4>
    <p>
      To preserve performance only <strong> {{ visible }} of {{ total }} </strong> files are
      displayed.
    </p>
  </div>
</template>
