<script>
export default {
  provide() {
    return {
      // We can't use this.vuexModule due to bug in vue-apollo when
      // provide is called in beforeCreate
      // See https://github.com/vuejs/vue-apollo/pull/1153 for details

      // @vue-compat does not care to normalize propsData fields
      vuexModule: this.$options.propsData.vuexModule ?? this.$options.propsData['vuex-module'],
    };
  },
  props: {
    vuexModule: {
      type: String,
      required: true,
    },
  },
  render() {
    return this.$scopedSlots.default?.();
  },
};
</script>
