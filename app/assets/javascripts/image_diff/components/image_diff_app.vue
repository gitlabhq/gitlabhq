<script>
  import { mapActions } from 'vuex';
  import store from '../stores/';
  import imageDiffProps from './../mixins/image_diff_props';
  import imageReplaced from './image_replaced.vue';
  import imageFrame from './image_frame.vue';

  export default {
    name: 'imageDiffApp',
    props: {
      coordinates: {
        type: Array,
        required: true,
      },
    },
    store,
    mixins: [imageDiffProps],
    components: {
      imageReplaced,
      imageFrame,
    },
    methods: {
      ...mapActions({
        setImages: 'setImages',
        setCoordinates: 'setCoordinates',
      }),
      styleCoordinate(coordinate) {
        return `left: ${coordinate.x}px; top: ${coordinate.y}px`;
      },
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
    created() {
      this.setImages(this.images);
      this.setCoordinates(this.coordinates);
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
      >
        <!-- TODO: Display coordinates after image load -->
        <button
          v-for="(coordinate, index) in coordinates"
          :key="index"
          class="badge"
          :style="styleCoordinate(coordinate)"
        >
          {{index + 1}}
        </button>
      </image-frame>
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
