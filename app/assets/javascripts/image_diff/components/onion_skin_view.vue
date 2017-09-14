<script>
  export default {
    name: 'onionSkinView',
    data() {
      return {
        dragging: false,
      };
    },
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
    mounted() {
      const file = this.$el.closest('.images');
      const context = {
        file,
        initDraggable: gl.ImageFile.prototype.initDraggable,
      };
      gl.ImageFile.prototype.views['onion-skin'].call(context);
    },
  };
</script>

<template>
  <div class="onion-skin view">
    <div class="onion-skin-frame">
      <div class="frame deleted">
        <img
          :src="deleted.path"
          :alt="deleted.alt" />
      </div>
      <div class="frame added">
        <img
          :src="added.path"
          :alt="added.alt" />
      </div>
      <div class="controls">
        <div class="transparent"></div>
        <div class="drag-track">
          <div class="dragger" style="left: 0px"></div>
          <div class="opaque"></div>
        </div>
      </div>
    </div>
  </div>
</template>
