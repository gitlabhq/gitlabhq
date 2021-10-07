import { __ } from '~/locale';
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

    return h(
      'div',
      {
        attrs: {
          role: 'region',
          'aria-label': __('Merge request reports'),
        },
      },
      [
        h(
          'ul',
          {
            class: 'gl-p-0 gl-m-0 gl-list-style-none',
          },
          [
            ...extensions.map((extension, index) =>
              h('li', { attrs: { class: index > 0 && 'mr-widget-border-top' } }, [
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
              ]),
            ),
          ],
        ),
      ],
    );
  },
};
