<script>
export default {
  props: {
    hasUnsavedChanges: {
      type: Boolean,
      required: true,
    },
  },
  created() {
    window.addEventListener('beforeunload', this.confirmChanges);
  },
  destroyed() {
    window.removeEventListener('beforeunload', this.confirmChanges);
  },
  methods: {
    confirmChanges(e = {}) {
      if (this.hasUnsavedChanges) {
        e.preventDefault();
        // eslint-disable-next-line no-param-reassign
        e.returnValue = ''; // Chrome requires returnValue to be set
      }
    },
  },
  render: () => null,
};
</script>
