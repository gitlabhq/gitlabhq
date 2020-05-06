export const Editor = {
  props: {
    initialValue: {
      type: String,
      required: true,
    },
    options: {
      type: Object,
    },
    initialEditType: {
      type: String,
    },
    height: {
      type: String,
    },
  },
  render(h) {
    return h('div');
  },
};

export const Viewer = {
  render(h) {
    return h('div');
  },
};
