/**
 * vue-virtual-scroll-list-vue3
 *
 * Ported from vue-virtual-scroll-list@1.4.7 (MIT License, author: TANG)
 * https://github.com/tangbc/vue-virtual-scroll-list
 *
 * Stripped unused features: item-mode (item/itemcount/itemprops props,
 * $scopedSlots.item), variable height mode, istable mode,
 * pagemode, start, offset, debounce, totop, tobottom, onscroll, wstyle.
 * Refactored for Vue 3 compatibility.
 */
import { h, defineComponent } from 'vue';

export default defineComponent({
  compatConfig: {
    MODE: 3,
  },
  props: {
    size: {
      type: Number,
      required: true,
    },
    remain: {
      type: Number,
      required: true,
    },
    rtag: {
      type: String,
      required: false,
      default: 'div',
    },
    wtag: {
      type: String,
      required: false,
      default: 'div',
    },
    wclass: {
      type: String,
      required: false,
      default: '',
    },
    scrollelement: {
      type: typeof window === 'undefined' ? Object : HTMLElement,
      required: false,
      default: null,
    },
    bench: {
      type: Number,
      required: false,
      default: 0,
    },
  },

  watch: {
    size() {
      this.changeProp = 'size';
    },
    remain() {
      this.changeProp = 'remain';
    },
    bench() {
      this.changeProp = 'bench';
    },
    scrollelement(newScrollelement, oldScrollelement) {
      if (oldScrollelement) {
        this.removeScrollListener(oldScrollelement);
      }
      if (newScrollelement) {
        this.addScrollListener(newScrollelement);
      }
    },
  },

  created() {
    const keeps = this.remain + (this.bench || this.remain);

    const delta = Object.create(null);
    delta.direction = '';
    delta.scrollTop = 0;
    delta.start = 0;
    delta.end = keeps - 1;
    delta.keeps = keeps;
    delta.total = 0;
    delta.offsetAll = 0;
    delta.paddingTop = 0;
    delta.paddingBottom = 0;

    this.delta = delta;
  },

  mounted() {
    if (this.scrollelement) {
      this.addScrollListener(this.scrollelement);
    }
  },

  beforeUnmount() {
    if (this.scrollelement) {
      this.removeScrollListener(this.scrollelement);
    }
  },

  beforeUpdate() {
    const { delta } = this;
    delta.keeps = this.remain + (this.bench || this.remain);

    const zone = this.getZone(delta.start);

    if (this.changeProp && this.changeProp === 'size') {
      const scrollTop =
        zone.isLast && delta.total - delta.start <= this.remain
          ? delta.total * this.size
          : delta.start * this.size;

      this.$nextTick(this.setScrollTop.bind(this, scrollTop));
    }

    if (this.changeProp || delta.end !== zone.end || delta.start !== zone.start) {
      this.changeProp = '';
      delta.end = zone.end;
      delta.start = zone.start;
      this.forceRender();
    }
  },

  methods: {
    addScrollListener(element) {
      element.addEventListener('scroll', this.onScroll, { passive: true });
    },

    removeScrollListener(element) {
      element.removeEventListener('scroll', this.onScroll, false);
    },

    onScroll() {
      const { delta } = this;
      const { vsl } = this.$refs;
      let currentOffset;

      if (this.scrollelement) {
        const scrollelementRect = this.scrollelement.getBoundingClientRect();
        const elemRect = this.$el.getBoundingClientRect();
        currentOffset = scrollelementRect.top - elemRect.top;
      } else {
        currentOffset = (vsl && (vsl.$el || vsl).scrollTop) || 0;
      }

      delta.direction = currentOffset > delta.scrollTop ? 'D' : 'U';
      delta.scrollTop = currentOffset;

      if (delta.total > delta.keeps) {
        this.updateZone(currentOffset);
      } else {
        delta.end = delta.total - 1;
      }
    },

    updateZone(offset) {
      const { delta } = this;
      let overs = Math.floor(offset / this.size);

      if (delta.direction === 'U') {
        overs = overs - this.remain + 1;
      }

      const zone = this.getZone(overs);
      const benchVal = this.bench || this.remain;

      const shouldRenderNextZone = Math.abs(overs - delta.start - benchVal) === 1;
      if (
        !shouldRenderNextZone &&
        overs - delta.start <= benchVal &&
        !zone.isLast &&
        overs > delta.start
      ) {
        return;
      }

      if (shouldRenderNextZone || zone.start !== delta.start || zone.end !== delta.end) {
        delta.end = zone.end;
        delta.start = zone.start;
        this.forceRender();
      }
    },

    getZone(idx) {
      let start;
      const { delta } = this;

      const index = Math.max(0, parseInt(idx, 10));

      const lastStart = delta.total - delta.keeps;
      const isLast = (index <= delta.total && index >= lastStart) || index > delta.total;

      if (isLast) {
        start = Math.max(0, lastStart);
      } else {
        start = index;
      }
      let end = start + delta.keeps - 1;
      if (delta.total && end > delta.total) {
        end = delta.total - 1;
      }

      return { end, start, isLast };
    },

    forceRender() {
      window.requestAnimationFrame(() => {
        this.$forceUpdate();
      });
    },

    setScrollTop(scrollTop) {
      if (this.scrollelement) {
        this.scrollelement.scrollTo(0, scrollTop);
      } else {
        const { vsl } = this.$refs;
        if (vsl) {
          (vsl.$el || vsl).scrollTop = scrollTop;
        }
      }
    },

    filter() {
      const { delta } = this;
      // eslint-disable-next-line @gitlab/vue-prefer-dollar-scopedslots
      const defaultSlot = this.$slots.default;
      const slots = (typeof defaultSlot === 'function' ? defaultSlot() : defaultSlot) || [];

      if (!slots.length) {
        delta.start = 0;
      }
      delta.total = slots.length;

      const hasPadding = delta.total > delta.keeps;
      const allHeight = this.size * delta.total;
      const paddingTop = this.size * (hasPadding ? delta.start : 0);
      const paddingBottom = this.size * (hasPadding ? delta.total - delta.keeps : 0) - paddingTop;

      delta.paddingTop = paddingTop;
      delta.paddingBottom = Math.max(0, paddingBottom < this.size ? 0 : paddingBottom);
      delta.offsetAll = allHeight - this.size * this.remain;

      const renders = [];
      for (let i = delta.start; i < delta.total && i <= Math.ceil(delta.end); i += 1) {
        renders.push(slots[i]);
      }

      return renders;
    },
  },

  render() {
    const list = this.filter();
    const { paddingTop, paddingBottom } = this.delta;

    const renderList = h(
      this.wtag,
      {
        style: {
          display: 'block',
          'padding-top': `${paddingTop}px`,
          'padding-bottom': `${paddingBottom}px`,
        },
        class: this.wclass,
        role: 'group',
      },
      list,
    );

    if (this.scrollelement) {
      return renderList;
    }

    return h(
      this.rtag,
      {
        ref: 'vsl',
        style: {
          display: 'block',
          'overflow-y': this.size >= this.remain ? 'auto' : 'initial',
          height: `${this.size * this.remain}px`,
        },
        onScrollPassive: this.onScroll,
      },
      [renderList],
    );
  },
});
