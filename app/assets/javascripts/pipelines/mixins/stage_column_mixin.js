export default {
  props: {
    hasTriggeredBy: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    buildConnnectorClass(index) {
      return index === 0 && (!this.isFirstColumn || this.hasTriggeredBy) ? 'left-connector' : '';
    },
  },
};
