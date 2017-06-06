function $filterFind(el, selector) {
  return $(el)
    .find('*')         // Take the current selection and find all descendants,
    .addBack()         // add the original selection back to the set
    .filter(selector); // and filter by the selector.
}

export default {
  mounted() {
    $filterFind(this.$el, '.js-vue-tooltip').tooltip();
  },

  updated() {
    $filterFind(this.$el, '.js-vue-tooltip').tooltip('fixTitle');
  },

  beforeDestroy() {
    $filterFind(this.$el, '.js-vue-tooltip').tooltip('destroy');
  },
};
