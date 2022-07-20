<script>
import { debounce } from 'lodash';
import {
  LOADING_CONTENT_EVENT,
  LOADING_SUCCESS_EVENT,
  LOADING_ERROR_EVENT,
  ALERT_EVENT,
} from '../constants';

export const tiptapToComponentMap = {
  update: 'docUpdate',
  selectionUpdate: 'selectionUpdate',
  transaction: 'transaction',
  focus: 'focus',
  blur: 'blur',
};

export const eventHubEvents = [
  ALERT_EVENT,
  LOADING_CONTENT_EVENT,
  LOADING_SUCCESS_EVENT,
  LOADING_ERROR_EVENT,
];

const getComponentEventName = (tiptapEventName) => tiptapToComponentMap[tiptapEventName];

export default {
  inject: ['tiptapEditor', 'eventHub'],
  created() {
    this.disposables = [];

    Object.keys(tiptapToComponentMap).forEach((tiptapEvent) => {
      const eventHandler = debounce(
        (params) => this.bubbleEvent(getComponentEventName(tiptapEvent), params),
        100,
      );

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
