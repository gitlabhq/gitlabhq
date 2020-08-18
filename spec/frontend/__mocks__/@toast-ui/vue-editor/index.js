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
    previewStyle: {
      type: String,
    },
  },
  created() {
    const mockEditorApi = {
      eventManager: {
        addEventType: jest.fn(),
        listen: jest.fn(),
        removeEventHandler: jest.fn(),
      },
    };

    this.$emit('load', mockEditorApi);
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
