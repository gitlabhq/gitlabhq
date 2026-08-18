<script>
import { getSlotFunction, normalizeRender } from '~/lib/utils/vue3compat/normalize_render';

export default normalizeRender({
  name: 'StrategiesDefault',
  emits: ['change'],
  mounted() {
    this.$emit('change', { parameters: {} });
  },
  render() {
    return getSlotFunction(this)?.();
  },
});
</script>
