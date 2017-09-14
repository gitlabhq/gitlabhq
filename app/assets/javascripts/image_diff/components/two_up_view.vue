<script>
  export default {
    name: 'twoUpView',
    props: {
      added: {
        type: Object,
        required: true,
        // TODO: Add validation
      },
      deleted: {
        type: Object,
        required: true,
        // TODO: Add validation
      },
    },
    methods: {
      loadMeta(imageType, event) {
        // TODO: Determine why this doesn't render after change
        this.$nextTick(() => {
          this[imageType].width = event.target.naturalWidth;
          this[imageType].height = event.target.naturalHeight;
        });
      },
    },
  };
</script>

<template>
  <div class="two-up view">
    <div class="image-container">
      <div class="frame deleted">
        <img
          @load="loadMeta('deleted', $event)"
          :src="deleted.path"
          :alt="deleted.alt"
        >
      </div>
      <p class="image-info">
        <span class="meta-filesize">
          {{deleted.size}}
        </span>
        |
        <strong>W:</strong>
        <span class="meta-width">
          {{deleted.width}}px
        </span>
        |
        <strong>H:</strong>
        <span class="meta-height">
          {{deleted.height}}px
        </span>
      </p>
    </div>

    <div class="image-container">
      <div class="frame added">
        <img
          @load="loadMeta('added', $event)"
          :src="added.path"
          :alt="added.alt"
        >
      </div>
      <p class="image-info">
        <span class="meta-filesize">
          {{added.size}}
        </span>
        |
        <strong>W:</strong>
        <span class="meta-width">
          {{added.width}}px
        </span>
        |
        <strong>H:</strong>
        <span class="meta-height">
          {{added.height}}px
        </span>
      </p>
    </div>
  </div>
</template>
