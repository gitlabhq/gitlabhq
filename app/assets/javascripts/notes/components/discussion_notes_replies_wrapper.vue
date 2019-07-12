<script>
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
      return h('li', { class: 'discussion-collapsible bordered-box clearfix' }, [
        h('ul', { class: 'notes' }, children),
      ]);
    }

    return children;
  },
};
</script>
