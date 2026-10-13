<script>
// No imports, and a hand-written render(h) like many gitlab-ui components.
export default {
  name: 'SharedRenderFn',
  render(h) {
    return h('span', { attrs: { 'data-testid': 'content' } }, 'rendered');
  },
};
</script>
