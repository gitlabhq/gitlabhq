import { extensions } from './index';

export default {
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  render(h) {
    if (extensions.length === 0) return null;

    return h('div', {}, [
      ...extensions.map((extension) =>
        h(
          { ...extension },
          {
            props: {
              ...extension.props.reduce(
                (acc, key) => ({
                  ...acc,
                  [key]: this.mr[key],
                }),
                {},
              ),
            },
          },
        ),
      ),
    ]);
  },
};
