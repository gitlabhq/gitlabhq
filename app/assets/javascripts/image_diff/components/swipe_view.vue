<script>
  import * as imageReplacedProps from '../mixins/image_replaced_props';
  import imageFrame from './image_frame.vue';

  export default {
    name: 'swipeView',
    mixins: [imageReplacedProps.mixin],
    components: {
      imageFrame,
    },
    mounted() {
      const file = this.$el.closest('.images');
      const context = {
        file,
        initDraggable: gl.ImageFile.prototype.initDraggable,
      };
      gl.ImageFile.prototype.views.swipe.call(context);
    },
  };
</script>

<template>
  <div class="swipe view">
    <div class="swipe-frame">
      <image-frame
        className="deleted"
        :src="deleted.path"
        :alt="deleted.alt"
      />
      <div class="swipe-wrap">
        <image-frame
          className="added"
          :src="added.path"
          :alt="added.alt"
        />
      </div>
      <span class="swipe-bar">
        <span class="top-handle"></span>
        <span class="bottom-handle"></span>
      </span>
    </div>
  </div>
</template>
