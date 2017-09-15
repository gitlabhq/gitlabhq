<script>
  import imageDiffProps from './../mixins/image_diff_props';
  import twoUpView from './two_up_view.vue';
  import swipeView from './swipe_view.vue';
  import onionSkinView from './onion_skin_view.vue';
  import * as constants from './../constants';

  export default {
    name: 'imageReplaced',
    mixins: [imageDiffProps],
    data() {
      return {
        currentView: constants.TWO_UP,
      };
    },
    components: {
      twoUpView,
      swipeView,
      onionSkinView,
    },
    computed: {
      isCurrentViewTwoUp() {
        return this.currentView === constants.TWO_UP;
      },
      isCurrentViewSwipe() {
        return this.currentView === constants.SWIPE;
      },
      isCurrentViewOnionSkin() {
        return this.currentView === constants.ONION_SKIN;
      },
    },
    methods: {
      changeView(viewType) {
        this.currentView = viewType;
      },
      goToTwoUpView(event) {
        event.target.blur();
        this.changeView(constants.TWO_UP);
      },
      goToSwipeView(event) {
        event.target.blur();
        this.changeView(constants.SWIPE);
      },
      goToOnionSkinView(event) {
        event.target.blur();
        this.changeView(constants.ONION_SKIN);
      },
    },
  };
</script>

<template>
  <div class="image-replaced-view">
    <two-up-view
      v-if="isCurrentViewTwoUp"
      :added="images.added"
      :deleted="images.deleted"
    />
    <swipe-view
      v-else-if="isCurrentViewSwipe"
      :added="images.added"
      :deleted="images.deleted"
    />
    <onion-skin-view
      v-else-if="isCurrentViewOnionSkin"
      :added="images.added"
      :deleted="images.deleted"
    />
    <div class="btn-group btn-group-gray-link">
      <button
        class="btn btn-link"
        :class="[{ active: isCurrentViewTwoUp }]"
        @click="goToTwoUpView"
      >
        2-up
      </button>
      <button
        class="btn btn-link"
        :class="[{ active: isCurrentViewSwipe }]"
        @click="goToSwipeView"
      >
        Swipe
      </button>
      <button
        class="btn btn-link"
        :class="[{ active: isCurrentViewOnionSkin }]"
        @click="goToOnionSkinView"
      >
        Onion skin
      </button>
    </div>
  </div>
</template>
