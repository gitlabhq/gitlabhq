<script>
  import twoUpView from './two_up_view.vue';
  import swipeView from './swipe_view.vue';
  import onionSkinView from './onion_skin_view.vue';

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
      onionSkinView,
    },
    methods: {
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
    <onion-skin-view
      v-else-if="currentView === 'onion-skin'"
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
