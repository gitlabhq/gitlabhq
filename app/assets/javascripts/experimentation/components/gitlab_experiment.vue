<script>
import { normalizeRender } from '~/lib/utils/vue3compat/normalize_render';
import { getExperimentVariant } from '../utils';

export default normalizeRender({
  props: {
    name: {
      type: String,
      required: true,
    },
  },
  render() {
    return this.$scopedSlots?.[getExperimentVariant(this.name)]?.();
  },
});
</script>
