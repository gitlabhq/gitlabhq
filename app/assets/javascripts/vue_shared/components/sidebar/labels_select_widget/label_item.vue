<script>
import { GlLink, GlIcon } from '@gitlab/ui';

export default {
  functional: true,
  props: {
    label: {
      type: Object,
      required: true,
    },
    isLabelSet: {
      type: Boolean,
      required: true,
    },
    highlight: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  render(h, { props, listeners }) {
    const { label, highlight, isLabelSet } = props;

    const labelColorBox = h('span', {
      class: 'dropdown-label-box gl-flex-shrink-0 gl-top-0 gl-mr-3',
      style: {
        backgroundColor: label.color,
      },
      attrs: {
        'data-testid': 'label-color-box',
      },
    });

    const checkedIcon = h(GlIcon, {
      class: {
        'gl-mr-3 gl-flex-shrink-0': true,
        hidden: !isLabelSet,
      },
      props: {
        name: 'mobile-issue-close',
      },
    });

    const noIcon = h('span', {
      class: {
        'gl-mr-5 gl-pr-3': true,
        hidden: isLabelSet,
      },
      attrs: {
        'data-testid': 'no-icon',
      },
    });

    const labelTitle = h('span', label.title);

    const labelLink = h(
      GlLink,
      {
        class: 'gl-display-flex gl-align-items-center label-item gl-text-black-normal',
        on: {
          click: () => {
            listeners.clickLabel(label);
          },
        },
      },
      [noIcon, checkedIcon, labelColorBox, labelTitle],
    );

    return h(
      'li',
      {
        class: {
          'gl-display-block': true,
          'gl-text-left': true,
          'is-focused': highlight,
        },
      },
      [labelLink],
    );
  },
};
</script>
