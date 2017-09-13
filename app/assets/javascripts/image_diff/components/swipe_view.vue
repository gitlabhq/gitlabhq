<script>
  export default {
    name: 'swipeView',
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
    methods: {
      mousedown() {
        this.dragging = true;
        $('body').css('user-select', 'none');
      },
      mouseup() {
        this.dragging = false;
        $('body').css('user-select', '');
      },
      movebar(event) {
        if (!this.dragging) return;

        this.dragging = false;

        const swipeFrame = this.$el.querySelector('.swipe-frame');
        const swipeWrap = this.$el.querySelector('.swipe-wrap');
        const swipeBar = this.$el.querySelector('.swipe-bar');

        const padding = parseInt(swipeWrap.style.right.replace('px', ''), 10) || 0;
        const left = event.pageX - (event.target.offsetLeft + padding);

        // debugger
        if (left > 0 && left < swipeWrap.style.width - (padding * 2)) {

        this.$nextTick(() => {
          swipeWrap.style.width = (this.maxWidth + 1) - left;
          swipeBar.style.left = `${left}px`;
        });
        }
      },
    },
    mounted() {
      const addedImage = this.$el.querySelector('.added img');
      const deletedImage = this.$el.querySelector('.deleted img');

      this.maxWidth = Math.max(addedImage.width, deletedImage.width);
      this.maxHeight = Math.max(addedImage.height, deletedImage.height);

      const swipeFrame = this.$el.querySelector('.swipe-frame');
      const swipeWrap = this.$el.querySelector('.swipe-wrap');
      const swipeBar = this.$el.querySelector('.swipe-bar');

      swipeFrame.style.width = `${this.maxWidth + 16}px`;
      swipeFrame.style.height = `${this.maxHeight + 28}px`;

      swipeWrap.style.width = `${this.maxWidth + 1}px`;
      swipeWrap.style.height = `${this.maxWidth + 2}px`;

      swipeBar.style.left = 0;
    },
  };
</script>

<template>
  <div class="swipe view">
    <div class="swipe-frame">
      <div class="frame deleted">
        <img
          :src="deleted.path"
          :alt="deleted.alt" />
      </div>
      <div class="swipe-wrap">
        <div class="frame added">
          <img
            :src="added.path"
            :alt="added.alt" />
        </div>
      </div>
      <span
        class="swipe-bar"
        @mousedown="mousedown"
        @mouseup="mouseup"
        @mousemove="movebar"
      >
        <span class="top-handle"></span>
        <span class="bottom-handle"></span>
      </span>
    </div>
  </div>
</template>
