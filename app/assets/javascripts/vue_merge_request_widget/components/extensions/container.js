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

    return h(
      'section',
      {
        attrs: {
          role: 'region',
          'aria-label': __('Merge request reports'),
        },
      },
      [
        h('div', { attrs: { class: 'mr-widget-section' } }, [
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
                        mr: this.mr,
                      },
                    },
                  ),
                ]),
              ),
            ],
          ),
        ]),
      ],
    );
  },
};
