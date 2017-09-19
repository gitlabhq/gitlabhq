<script>
  import Vue from 'vue';
  import Translate from '../../vue_shared/translate';
  import imageDiffProps from '../mixins/image_diff_props';
  import twoUpView from './two_up_view.vue';
  import swipeView from './swipe_view.vue';
  import onionSkinView from './onion_skin_view.vue';
  import constantViewTypes from '../constants';

  Vue.use(Translate);

  export default {
    name: 'imageReplaced',
    mixins: [imageDiffProps],
    data() {
      return {
        // Use constantViewTypes because computed viewTypes() is not defined yet
        currentView: constantViewTypes.TWO_UP,
      };
    },
    components: {
      twoUpView,
      swipeView,
      onionSkinView,
    },
    computed: {
      viewTypes() {
        return constantViewTypes;
      },
      isCurrentViewTwoUp() {
        return this.currentView === this.viewTypes.TWO_UP;
      },
      isCurrentViewSwipe() {
        return this.currentView === this.viewTypes.SWIPE;
      },
      isCurrentViewOnionSkin() {
        return this.currentView === this.viewTypes.ONION_SKIN;
      },
    },
    methods: {
      goToView(viewType, event) {
        event.target.blur();
        this.currentView = viewType;
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
        type="button"
        class="btn btn-link"
        :class="{ active: isCurrentViewTwoUp }"
        @click="goToView(viewTypes.TWO_UP, $event)"
      >
        {{ __('2-up') }}
      </button>
      <button
        type="button"
        class="btn btn-link"
        :class="{ active: isCurrentViewSwipe }"
        @click="goToView(viewTypes.SWIPE, $event)"
      >
        {{ __('Swipe') }}
      </button>
      <button
        type="button"
        class="btn btn-link"
        :class="{ active: isCurrentViewOnionSkin }"
        @click="goToView(viewTypes.ONION_SKIN, $event)"
      >
        {{ __('Onion skin') }}
      </button>
    </div>
  </div>
</template>
