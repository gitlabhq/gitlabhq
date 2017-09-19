<script>
  import { mapGetters, mapActions } from 'vuex';
  import store from '../stores/';
  import imageReplaced from './image_replaced.vue';
  import imageFrame from './image_frame.vue';

  export default {
    name: 'imageDiffApp',
    props: {
      initialImages: {
        type: Object,
        required: true,
        validator: value => value.added || value.deleted,
      },
      initialCoordinates: {
        type: Array,
        required: true,
      },
      uid: {
        type: Number,
        required: true,
      },
    },
    store,
    components: {
      imageReplaced,
      imageFrame,
    },
    computed: {
      ...mapGetters([
        'getCoordinates',
        'getImages',
      ]),
      images() {
        return this.getImages(this.uid);
      },
      coordinates() {
        return this.getCoordinates(this.uid);
      },
      isImageReplaced() {
        return this.images.added && this.images.deleted;
      },
      isImageAdded() {
        return !!this.images.added;
      },
      currentImage() {
        return this.images.added || this.images.deleted;
      },
      currentImageFrameClass() {
        return !this.isImageReplaced && this.isImageAdded ? 'added' : 'deleted';
      },
    },
    methods: {
      ...mapActions({
        addImageDiff: 'addImageDiff',
        actionAddCoordinate: 'addCoordinate',
      }),
      addCoordinate(event) {
        const container = event.target.parentElement;
        const x = event.offsetX ? (event.offsetX) : event.pageX - container.offsetLeft;
        const y = event.offsetY ? (event.offsetY) : event.pageY - container.offsetTop;

        // TODO: Disable add coordinate when user is not logged in

        // TODO: Include cursor image offset into x, y calculation

        // TODO: Do not allow multiple copies of the same coordinate

        this.actionAddCoordinate({
          imageDiffId: this.uid,
          coordinate: {
            x,
            y,
          },
        });
      },
    },
    created() {
      this.addImageDiff({
        id: this.uid,
        images: this.initialImages,
        coordinates: this.initialCoordinates,
      });
    },
  };
</script>

<template>
  <div class="image">
    <image-replaced
      v-if="isImageReplaced"
      :images="images"
    />
    <span
      v-else
      class="wrap"
    >
      <image-frame
        :class-name="currentImageFrameClass"
        :src="currentImage.path"
        :alt="currentImage.alt"
        @click="addCoordinate"
        :coordinates="coordinates"
      />
      <p class="image-info">
        {{currentImage.size}}
      </p>
    </span>
  </div>
</template>
