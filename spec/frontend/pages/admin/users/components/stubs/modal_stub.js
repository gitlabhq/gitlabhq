const ModalStub = {
  inheritAttrs: false,
  name: 'glmodal-stub',
  data() {
    return {
      showWasCalled: false,
    };
  },
  methods: {
    show() {
      this.showWasCalled = true;
    },
    hide() {},
  },
  render(h) {
    const children = [this.$slots.default, this.$slots['modal-footer']]
      .filter(Boolean)
      .reduce((acc, nodes) => acc.concat(nodes), []);
    return h('div', children);
  },
};

export default ModalStub;
