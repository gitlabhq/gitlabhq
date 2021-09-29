import { registeredExtensions } from './index';

export default {
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  render(h) {
    const { extensions } = registeredExtensions;

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
