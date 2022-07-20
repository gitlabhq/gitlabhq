<script>
import { isEqual, isString } from 'lodash';

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

      this.saveValue(this.serialize(newVal));
    },
    clear(newVal) {
      if (newVal) {
        localStorage.removeItem(this.storageKey);
      }
    },
  },
  mounted() {
    // On mount, trigger update if we actually have a localStorageValue
    const { exists, value } = this.getStorageValue();

    if (exists && !isEqual(value, this.value)) {
      this.$emit('input', value);
    }
  },
  methods: {
    getStorageValue() {
      const value = localStorage.getItem(this.storageKey);

      if (value === null) {
        return { exists: false };
      }

      try {
        return { exists: true, value: this.deserialize(value) };
      } catch {
        // eslint-disable-next-line no-console
        console.warn(
          `[gitlab] Failed to deserialize value from localStorage (key=${this.storageKey})`,
          value,
        );
        // default to "don't use localStorage value"
        return { exists: false };
      }
    },
    saveValue(val) {
      localStorage.setItem(this.storageKey, val);
    },
    serialize(val) {
      if (!isString(val) && this.asString) {
        // eslint-disable-next-line no-console
        console.warn(
          `[gitlab] LocalStorageSync is saving`,
          val,
          `to the key "${this.storageKey}", but it is not a string and the 'asString' prop is true. This will save and restore the stringified value rather than the original value. If this is not intended, please remove or set the 'asString' prop to false.`,
        );
      }

      return this.asString ? val : JSON.stringify(val);
    },
    deserialize(val) {
      return this.asString ? val : JSON.parse(val);
    },
  },
  render() {
    return this.$scopedSlots.default?.();
  },
};
</script>
