import { extensions } from './index';

export default {
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  render(h) {
    return h(
      'div',
      {},
      extensions.map((extension) =>
        h(extension, {
          props: extensions[0].props.reduce(
            (acc, key) => ({
              ...acc,
              [key]: this.mr[key],
            }),
            {},
          ),
        }),
      ),
    );
  },
};
