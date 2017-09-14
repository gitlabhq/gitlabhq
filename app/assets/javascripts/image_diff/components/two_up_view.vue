<script>
  import * as imageReplacedProps from './../mixins/image_replaced_props';
  import imageFrame from './image_frame.vue';

  export default {
    name: 'twoUpView',
    mixins: [imageReplacedProps.mixin],
    components: {
      imageFrame,
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
      <image-frame
        @imageLoaded="loadMeta('deleted', $event)"
        className="deleted"
        :src="deleted.path"
        :alt="deleted.alt"
      />
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
      <image-frame
        @imageLoaded="loadMeta('added', $event)"
        className="added"
        :src="added.path"
        :alt="added.alt"
      />
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
