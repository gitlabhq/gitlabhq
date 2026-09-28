<script>
// Intentionally has no imports (see shared_v_show.vue) and a hand-written render
// function that takes `h` as an argument, as many gitlab-ui components do.
export default {
  name: 'SharedRenderFn',
  render(h) {
    return h('span', { attrs: { 'data-testid': 'content' } }, 'rendered');
  },
};
</script>
