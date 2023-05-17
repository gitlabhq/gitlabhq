<script>
import { debounce } from 'lodash';
import { ALERT_EVENT, KEYDOWN_EVENT } from '../constants';

export const tiptapToComponentMap = {
  update: 'docUpdate',
  selectionUpdate: 'selectionUpdate',
  transaction: 'transaction',
  focus: 'focus',
  blur: 'blur',
};

export const eventHubEvents = [ALERT_EVENT, KEYDOWN_EVENT];

const getComponentEventName = (tiptapEventName) => tiptapToComponentMap[tiptapEventName];

export default {
  inject: ['tiptapEditor', 'eventHub'],
  props: {
    debounce: {
      type: Number,
      required: false,
      default: 100,
    },
  },
  created() {
    this.disposables = [];

    Object.keys(tiptapToComponentMap).forEach((tiptapEvent) => {
      let eventHandler = (params) => this.bubbleEvent(getComponentEventName(tiptapEvent), params);
      if (this.debounce) {
        eventHandler = debounce(eventHandler, this.debounce);
      }

      this.tiptapEditor?.on(tiptapEvent, eventHandler);

      this.disposables.push(() => this.tiptapEditor?.off(tiptapEvent, eventHandler));
    });

    eventHubEvents.forEach((event) => {
      const handler = (...params) => {
        this.bubbleEvent(event, ...params);
      };

      this.eventHub.$on(event, handler);
      this.disposables.push(() => this.eventHub?.$off(event, handler));
    });
  },
  beforeDestroy() {
    this.disposables.forEach((dispose) => dispose());
  },
  methods: {
    bubbleEvent(eventHubEvent, params) {
      this.$emit(eventHubEvent, params);
    },
  },
  render() {
    return this.$scopedSlots.default?.();
  },
};
</script>
