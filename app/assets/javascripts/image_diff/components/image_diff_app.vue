<script>
  import imageReplaced from './image_replaced.vue';
  export default {
    name: 'imageDiffApp',
    props: {
      images: {
        type: Object,
        required: true,
        // TODO: Add validation to make sure that there is at least an added or deleted
      },
    },
    components: {
      imageReplaced,
    },
    computed: {
      isImageReplaced() {
        return this.images.added && this.images.deleted;
      },
      isImageAdded() {
        return this.images.added !== null;
      },
      currentImage() {
        return this.images.added || this.images.deleted;
      },
      currentImageFrameClass() {
        return !this.isImageReplaced && this.isImageAdded? 'frame added' : 'frame deleted';
      }
    },
    mounted() {
      // const diffFile = this.$el.closest('.diff-file');
      // new gl.ImageFile(diffFile);
    },
  };
</script>

<template>
  <div class="image">
    <span
      v-if="!isImageReplaced"
      class="wrap">
      <div :class="currentImageFrameClass">
        <img
          :src="currentImage.path"
          :alt="currentImage.alt" />
      </div>
      <p class="image-info">
        {{currentImage.size}}
      </p>
    </span>
    <image-replaced
      v-else
      :images="images"
    />
  </div>
</template>
