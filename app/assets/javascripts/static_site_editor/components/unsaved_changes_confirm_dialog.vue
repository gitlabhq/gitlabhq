<script>
export default {
  props: {
    modified: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  created() {
    window.addEventListener('beforeunload', this.requestConfirmation);
  },
  destroyed() {
    window.removeEventListener('beforeunload', this.requestConfirmation);
  },
  methods: {
    requestConfirmation(e) {
      if (this.modified) {
        e.preventDefault();
        // eslint-disable-next-line no-param-reassign
        e.returnValue = '';
      }
    },
  },
  render: () => null,
};
</script>
