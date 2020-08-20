<script>
import { queryToObject, setUrlParams, updateHistory } from '~/lib/utils/url_utility';

export default {
  props: {
    page: {
      type: Number,
      required: true,
    },
  },

  watch: {
    page(newPage) {
      updateHistory({
        url: setUrlParams({
          page: newPage === 1 ? null : newPage,
        }),
      });
    },
  },

  created() {
    window.addEventListener('popstate', this.updatePage);
  },

  beforeDestroy() {
    window.removeEventListener('popstate', this.updatePage);
  },

  methods: {
    updatePage() {
      const page = parseInt(queryToObject(window.location.search).page, 10) || 1;
      this.$emit('popstate', page);
    },
  },

  render: () => null,
};
</script>
