<script>
import { getExperimentVariant } from '../utils';

export default {
  props: {
    name: {
      type: String,
      required: true,
    },
  },
  render() {
    return this.$scopedSlots?.[getExperimentVariant(this.name)]?.();
  },
};
</script>
