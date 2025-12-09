import { Teleport, h } from 'vue';

export const MountingPortal = {
  name: 'MountingPortal',
  props: {
    mountTo: {
      type: String,
      required: true,
    },
    append: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      targetElement: null,
    };
  },
  computed: {
    teleportTarget() {
      return this.append && this.targetElement ? this.targetElement : this.mountTo;
    },
  },
  mounted() {
    if (this.append) {
      this.createTargetElement();
    }
  },
  beforeUnmount() {
    if (this.append && this.targetElement) {
      this.targetElement.remove();
      this.targetElement = null;
    }
  },
  methods: {
    createTargetElement() {
      const parent = document.querySelector(this.mountTo);
      if (parent) {
        const element = document.createElement('div');
        element.classList.add('vue-portal-target');
        parent.appendChild(element);
        this.targetElement = element;
      }
    },
  },
  render() {
    const rawResult = this.$scopedSlots.default();
    const result = Array.isArray(rawResult) && rawResult.length === 1 ? rawResult[0] : rawResult;
    return h(Teleport, { to: this.teleportTarget, defer: true }, result);
  },
};

export const PortalTarget = {
  name: 'PortalTarget',
  props: {
    name: {
      type: String,
      required: true,
    },
  },
  computed: {
    targetId() {
      return `portal-target-${this.name}`;
    },
  },
  render() {
    return h('div', { id: this.targetId });
  },
};

export const Portal = {
  props: {
    to: {
      type: String,
      required: true,
    },
  },
  computed: {
    targetSelector() {
      return `#portal-target-${this.to}`;
    },
  },
  render() {
    const rawResult = this.$scopedSlots.default();
    const result = Array.isArray(rawResult) && rawResult.length === 1 ? rawResult[0] : rawResult;
    return h(Teleport, { to: this.targetSelector, defer: true }, result);
  },
};

export const Wormhole = {
  hasTarget() {
    // used inside bootstrap-vue just to print warning
    return false;
  },
};

// Fake plugin, not needed in Vue3 since teleport is in core
export default {};
