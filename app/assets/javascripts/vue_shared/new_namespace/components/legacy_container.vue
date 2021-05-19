<script>
export default {
  inheritAttrs: false,
  props: {
    selector: {
      type: String,
      required: true,
    },
  },
  mounted() {
    const legacyEntry = document.querySelector(this.selector);
    if (legacyEntry.tagName === 'TEMPLATE') {
      this.$el.innerHTML = legacyEntry.innerHTML;
    } else {
      this.source = legacyEntry.parentNode;
      this.$el.appendChild(legacyEntry);
      legacyEntry.classList.add('active');
    }
  },

  beforeDestroy() {
    if (this.source) {
      this.$el.firstChild.classList.remove('active');
      this.source.appendChild(this.$el.firstChild);
    }
  },
};
</script>
<template>
  <div></div>
</template>
