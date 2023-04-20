<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

// @deprecated This component should only be used when there is no GraphQL API.
// In most cases you should use
// `app/assets/javascripts/sidebar/components/labels/labels_select_widget/label_item.vue` instead.
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
    isLabelIndeterminate: {
      type: Boolean,
      required: false,
      default: false,
    },
    highlight: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  render(h, { props, listeners }) {
    const { label, highlight, isLabelSet, isLabelIndeterminate } = props;

    const labelColorBox = h('span', {
      class: 'dropdown-label-box gl-flex-shrink-0 gl-top-0 gl-absolute',
      style: {
        backgroundColor: label.color,
      },
      attrs: {
        'data-testid': 'label-color-box',
      },
    });

    const checkedIcon = h(GlIcon, {
      class: {
        'gl-mr-3 gl-flex-shrink-0 has-tooltip': true,
        hidden: !isLabelSet,
      },
      attrs: {
        title: __('Selected for all items.'),
        'data-testid': 'checked-icon',
      },
      props: {
        name: 'mobile-issue-close',
      },
    });

    const indeterminateIcon = h(GlIcon, {
      class: {
        'gl-mr-3 gl-flex-shrink-0 has-tooltip': true,
        hidden: !isLabelIndeterminate,
      },
      attrs: {
        title: __('Selected for some items.'),
        'data-testid': 'indeterminate-icon',
      },
      props: {
        name: 'dash',
      },
    });

    const noIcon = h('span', {
      class: {
        'gl-mr-5 gl-pr-3': true,
        hidden: isLabelSet || isLabelIndeterminate,
      },
      attrs: {
        'data-testid': 'no-icon',
      },
    });

    const labelTitle = h('span', label.title);

    const labelLink = h(
      GlLink,
      {
        class: 'gl-display-flex gl-align-items-center label-item gl-text-body',
        on: {
          click: () => {
            listeners.clickLabel(label);
          },
        },
      },
      [noIcon, checkedIcon, indeterminateIcon, labelColorBox, labelTitle],
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
