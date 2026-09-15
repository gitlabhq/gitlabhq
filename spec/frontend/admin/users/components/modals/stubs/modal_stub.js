const ModalStub = {
  inheritAttrs: false,
  name: 'glmodal-stub',
  props: {
    actionPrimary: {
      type: Object,
      required: false,
      default: null,
    },
    actionCancel: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      showWasCalled: false,
      hideWasCalled: false,
    };
  },
  methods: {
    show() {
      this.showWasCalled = true;
    },
    hide() {
      this.hideWasCalled = true;
    },
  },
  render(h) {
    const children = [this.$slots.default, this.$slots['modal-footer']]
      .filter(Boolean)
      .reduce((acc, nodes) => acc.concat(nodes), []);
    return h('div', children);
  },
};

export default ModalStub;
