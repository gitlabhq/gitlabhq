<script>
import { normalizeChildren } from '~/lib/utils/vue3compat/normalize_children';
/**
 * Wrapper for discussion notes replies section.
 *
 * This is a functional component using the render method because in some cases
 * the wrapper is not needed and we want to simply render along the children.
 */
export default {
  functional: true,
  props: {
    isDiffDiscussion: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  render(h, { props, children }) {
    if (props.isDiffDiscussion) {
      return h(
        'li',
        {
          class:
            'discussion-collapsible gl-border-solid gl-border-default gl-border-1 gl-rounded-base gl-border-t-0',
        },
        [h('ul', { class: 'notes' }, children)],
      );
    }

    return normalizeChildren(children);
  },
};
</script>
