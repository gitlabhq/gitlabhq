<script>
  import { mapGetters, mapActions } from 'vuex';
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
      uid: {
        type: Number,
        required: true,
      },
    },
    store,
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
    methods: {
      // ...mapGetters({
      //   getImages: 'images',
      // }),
      ...mapActions({
        addImageDiff: 'addImageDiff',
        actionAddCoordinate: 'addCoordinate',
      }),
      addCoordinate(event) {
        const container = event.target.parentElement;
        const x = event.offsetX ? (event.offsetX) : event.pageX - container.offsetLeft;
        const y = event.offsetY ? (event.offsetY) : event.pageY - container.offsetTop;

        // TODO: Include cursor image offset into x, y calculation
        // debugger
        // TODO: Do not allow multiple copies of the same coordinate
        // this.actionAddCoordinate({
        //   x,
        //   y,
        // });

        this.actionAddCoordinate({
          imageDiffId: this.uid,
          x,
          y,
        })
      },
    },
    created() {
      // this.setImages(this.images);
      // this.setCoordinates(this.coordinates);

      this.addImageDiff({
        id: this.uid,
        images: this.images,
        coordinates: this.coordinates,
      });
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
        @click="addCoordinate"
        :coordinates="coordinates"
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
