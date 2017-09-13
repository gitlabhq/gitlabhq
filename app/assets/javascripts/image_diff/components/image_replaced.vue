<script>
  import twoUpView from './two_up_view.vue';
  import swipeView from './swipe_view.vue';

  export default {
    name: 'imageReplaced',
    data() {
      return {
        currentView: '2-up',
      };
    },
    props: {
      images: {
        type: Object,
        required: true,
        // TODO: Add validation to make sure that there is at least an added or deleted
      },
    },
    components: {
      twoUpView,
      swipeView,
    },
    methods: {
      loadMeta(imageType, event) {
        this.$nextTick(() => {
          this.images[imageType].width = event.target.naturalWidth;
          this.images[imageType].height = event.target.naturalHeight;
        });
      },
      changeView(viewType) {
        this.currentView = viewType;
      },
    },
  };
</script>

<template>
  <div class="image-replaced-view">
    <two-up-view
      v-if="currentView === '2-up'"
      :added="images.added"
      :deleted="images.deleted"
    />
    <swipe-view
      v-else-if="currentView === 'swipe'"
      :added="images.added"
      :deleted="images.deleted"
    />
    <div class="btn-group">
      <button class="btn btn-link" :class="[{ active: currentView === '2-up' }]" @click="changeView('2-up')">2-up</button>
      <button class="btn btn-link" :class="[{ active: currentView === 'swipe' }]" @click="changeView('swipe')">Swipe</button>
      <button class="btn btn-link" :class="[{ active: currentView === 'onion-skin' }]" @click="changeView('onion-skin')">Onion skin</button>
    </div>
  </div>
</template>
