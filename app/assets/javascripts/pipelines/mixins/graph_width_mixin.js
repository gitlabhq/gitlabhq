import { debounceByAnimationFrame } from '~/lib/utils/common_utils';
import { LAYOUT_CHANGE_DELAY } from '~/pipelines/constants';

export default {
  debouncedResize: null,
  sidebarMutationObserver: null,
  data() {
    return {
      graphLeftPadding: 0,
      graphRightPadding: 0,
    };
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.$options.debouncedResize);

    if (this.$options.sidebarMutationObserver) {
      this.$options.sidebarMutationObserver.disconnect();
    }
  },
  created() {
    this.$options.debouncedResize = debounceByAnimationFrame(this.setGraphPadding);
    window.addEventListener('resize', this.$options.debouncedResize);
  },
  mounted() {
    this.setGraphPadding();

    this.$options.sidebarMutationObserver = new MutationObserver(this.handleLayoutChange);
    this.$options.sidebarMutationObserver.observe(document.querySelector('.layout-page'), {
      attributes: true,
      childList: false,
      subtree: false,
    });
  },
  methods: {
    setGraphPadding() {
      // only add padding to main graph (not inline upstream/downstream graphs)
      if (this.type && this.type !== 'main') return;

      const container = document.querySelector('.js-pipeline-container');
      if (!container) return;

      this.graphLeftPadding = container.offsetLeft;
      this.graphRightPadding = window.innerWidth - container.offsetLeft - container.offsetWidth;
    },
    handleLayoutChange() {
      // wait until animations finish, then recalculate padding
      window.setTimeout(this.setGraphPadding, LAYOUT_CHANGE_DELAY);
    },
  },
};
