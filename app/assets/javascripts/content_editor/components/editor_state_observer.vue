<script>
import { debounce } from 'lodash';

export const tiptapToComponentMap = {
  update: 'docUpdate',
  selectionUpdate: 'selectionUpdate',
  transaction: 'transaction',
  focus: 'focus',
  blur: 'blur',
  error: 'error',
};

const getComponentEventName = (tiptapEventName) => tiptapToComponentMap[tiptapEventName];

export default {
  inject: ['tiptapEditor'],
  created() {
    this.disposables = [];

    Object.keys(tiptapToComponentMap).forEach((tiptapEvent) => {
      const eventHandler = debounce((params) => this.handleTipTapEvent(tiptapEvent, params), 100);

      this.tiptapEditor?.on(tiptapEvent, eventHandler);

      this.disposables.push(() => this.tiptapEditor?.off(tiptapEvent, eventHandler));
    });
  },
  beforeDestroy() {
    this.disposables.forEach((dispose) => dispose());
  },
  methods: {
    handleTipTapEvent(tiptapEvent, params) {
      this.$emit(getComponentEventName(tiptapEvent), params);
    },
  },
  render() {
    return this.$slots.default;
  },
};
</script>
