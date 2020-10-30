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
      class: 'dropdown-label-box',
      style: {
        backgroundColor: label.color,
      },
      attrs: {
        'data-testid': 'label-color-box',
      },
    });

    const checkedIcon = h(GlIcon, {
      class: {
        'mr-2 align-self-center': true,
        hidden: !isLabelSet,
      },
      props: {
        name: 'mobile-issue-close',
      },
    });

    const noIcon = h('span', {
      class: {
        'mr-3 pr-2': true,
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
        class: 'd-flex align-items-baseline text-break-word label-item',
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
          'd-block': true,
          'text-left': true,
          'is-focused': highlight,
        },
      },
      [labelLink],
    );
  },
};
</script>
