<script>
  import * as imageReplacedProps from './../mixins/image_replaced_props';
  import imageFrame from './image_frame.vue';

  export default {
    name: 'onionSkinView',
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
      // TODO: Create tech debt issue for refactoring gl.ImageFile
      gl.ImageFile.prototype.views['onion-skin'].call(context);
    },
  };
</script>

<template>
  <div class="onion-skin view">
    <div class="onion-skin-frame">
      <image-frame
        className="deleted"
        :src="deleted.path"
        :alt="deleted.alt"
      />
      <image-frame
        className="added"
        :src="added.path"
        :alt="added.alt"
      />
      <div class="controls">
        <div class="transparent"></div>
        <div class="drag-track">
          <div class="dragger"></div>
        </div>
        <div class="opaque"></div>
      </div>
    </div>
  </div>
</template>
