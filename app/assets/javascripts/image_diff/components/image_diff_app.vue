<script>
  import imageDiffProps from './../mixins/image_diff_props';
  import imageReplaced from './image_replaced.vue';
  import imageFrame from './image_frame.vue';

  export default {
    name: 'imageDiffApp',
    mixins: [imageDiffProps],
    components: {
      imageReplaced,
      imageFrame,
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
        return !this.isImageReplaced && this.isImageAdded ? 'added' : 'deleted';
      },
    },
  };
</script>

<template>
  <div class="image">
    <span
      v-if="!isImageReplaced"
      class="wrap"
    >
      <image-frame
        :className="currentImageFrameClass"
        :src="currentImage.path"
        :alt="currentImage.alt"
      />
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
