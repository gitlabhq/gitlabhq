<script>
import { isEqual } from 'lodash';
import { getStorageValue, saveStorageValue, removeStorageValue } from '~/lib/utils/local_storage';

/**
 * This component will save and restore a value to and from localStorage.
 * The value will be saved only when the value changes; the initial value won't be saved.
 *
 * By default, the value will be saved using JSON.stringify(), and retrieved back using JSON.parse().
 *
 * If you would like to save the raw string instead, you may set the 'asString' prop to true, though be aware that this is a
 * legacy prop to maintain backwards compatibility.
 *
 * For new components saving data for the first time, it's recommended to not use 'asString' even if you're saving a string; it will still be
 * saved and restored properly using JSON.stringify()/JSON.parse().
 */
export default {
  props: {
    storageKey: {
      type: String,
      required: true,
    },
    value: {
      type: [String, Number, Boolean, Array, Object],
      required: false,
      default: '',
    },
    asString: {
      type: Boolean,
      required: false,
      default: false,
    },
    persist: {
      type: Boolean,
      required: false,
      default: true,
    },
    clear: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  watch: {
    value(newVal) {
      if (!this.persist) return;

      saveStorageValue(this.storageKey, newVal, this.asString);
    },
    clear(newVal) {
      if (newVal) {
        removeStorageValue(this.storageKey);
      }
    },
  },
  mounted() {
    // On mount, trigger update if we actually have a localStorageValue
    const { exists, value } = getStorageValue(this.storageKey, this.asString);

    if (exists && !isEqual(value, this.value)) {
      this.$emit('input', value);
    }
  },
  render() {
    return this.$scopedSlots.default?.();
  },
};
</script>
