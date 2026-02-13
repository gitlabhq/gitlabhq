import { Teleport, h, reactive, cloneVNode } from 'vue';

const portalTargetAttrs = reactive({});

// Wormhole pattern: Portal registers content, PortalTarget renders it
// This avoids Teleport's issues with target element lifecycle which break portal-vue
const wormholeContent = reactive({});
const wormholeSource = reactive({});

export const MountingPortal = {
  name: 'MountingPortal',
  inheritAttrs: false,
  props: {
    append: {
      type: Boolean,
      default: false,
    },
    slim: {
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
    mountTo() {
      // Mimicking access from $attrs to be compatible with Vue.js 2 version
      return this.$attrs.mountTo || this.$attrs['mount-to'];
    },
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

let instanceCounter = 0;

export const PortalTarget = {
  name: 'PortalTarget',
  inheritAttrs: false,
  props: {
    name: {
      type: String,
      required: true,
    },
    slim: {
      type: Boolean,
      default: false,
    },
    // In Vue 3 compat mode, class/style may not be in $attrs depending on flags
    style: {
      type: [String, Object, Array],
      default: null,
    },
    class: {
      type: [String, Object, Array],
      default: null,
    },
  },
  computed: {
    targetId() {
      return `portal-target-${this.name}`;
    },
    mergedAttrs() {
      const attrs = { ...this.$attrs };
      if (this.style) attrs.style = this.style;
      if (this.class) attrs.class = this.class;
      return attrs;
    },
    portalContent() {
      return wormholeContent[this.name];
    },
  },
  beforeUnmount() {
    delete portalTargetAttrs[this.name];
  },
  render() {
    const content = this.portalContent;

    if (this.slim) {
      // In slim mode: pass attrs to Portal's content, wrapper is invisible
      portalTargetAttrs[this.name] = this.mergedAttrs;
      return h('div', { id: this.targetId, style: { display: 'contents' } }, content);
    }

    // Non-slim mode: attrs go on wrapper div, not passed to Portal
    delete portalTargetAttrs[this.name];
    return h('div', { id: this.targetId, ...this.mergedAttrs }, content);
  },
};

export const Portal = {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  name: 'Portal',
  props: {
    to: {
      type: String,
      required: true,
    },
    slim: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    instanceCounter += 1;
    return {
      instanceId: instanceCounter,
    };
  },
  computed: {
    targetAttrs() {
      return portalTargetAttrs[this.to];
    },
  },
  methods: {
    updateWormhole() {
      const rawResult = this.$scopedSlots.default?.() ?? [];
      let result = Array.isArray(rawResult) && rawResult.length === 1 ? rawResult[0] : rawResult;

      if (this.targetAttrs && result) {
        result = cloneVNode(result, this.targetAttrs);
      }

      // Only update if we own this slot or it's empty
      if (!wormholeSource[this.to] || wormholeSource[this.to] === this.instanceId) {
        wormholeSource[this.to] = this.instanceId;
        wormholeContent[this.to] = result;
      }
    },
  },
  beforeUnmount() {
    // Only clear if we own this slot
    if (wormholeSource[this.to] === this.instanceId) {
      delete wormholeContent[this.to];
      delete wormholeSource[this.to];
    }
  },
  render() {
    // Update wormhole on every render to keep content fresh
    this.updateWormhole();

    // Portal itself renders nothing - content is rendered by PortalTarget
    return null;
  },
};

export const Wormhole = {
  hasTarget(name) {
    return Boolean(wormholeContent[name]);
  },
};

// Fake plugin, not needed in Vue3 since teleport is in core
export default {};
