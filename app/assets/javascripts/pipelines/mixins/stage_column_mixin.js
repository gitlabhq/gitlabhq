export default {
  props: {
    hasUpstream: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    buildConnnectorClass(index) {
      return index === 0 && (!this.isFirstColumn || this.hasUpstream) ? 'left-connector' : '';
    },
  },
};
