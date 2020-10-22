<script>
import { isEqual } from 'lodash';

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
    asJson: {
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
      if (!this.persist) return;

      localStorage.setItem(this.storageKey, val);
    },
    serialize(val) {
      return this.asJson ? JSON.stringify(val) : val;
    },
    deserialize(val) {
      return this.asJson ? JSON.parse(val) : val;
    },
  },
  render() {
    return this.$slots.default;
  },
};
</script>
