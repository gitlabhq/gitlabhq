<script>
import { GlSegmentedControl } from '@gitlab/ui';

export default {
  name: 'ColorModeSelector',
  components: {
    GlSegmentedControl,
  },
  props: {
    colorModes: {
      type: Array,
      required: true,
    },
    initialColorModeId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      selectedColorModeId: this.initialColorModeId,
    };
  },
  computed: {
    options() {
      return this.colorModes.map((mode) => ({ value: mode.id, text: mode.name }));
    },
  },
  methods: {
    onChange(newColorModeId) {
      const previousColorModeId = this.selectedColorModeId;
      this.selectedColorModeId = newColorModeId;

      // Wait for the hidden input's :value to update before submitting.
      this.$nextTick(() => {
        this.submitForm(previousColorModeId);
      });
    },
    submitForm(previousColorModeId) {
      // Submit the preferences form so the change is persisted, mirroring the
      // auto-submit behavior the radio inputs had via profile.js. A successful
      // color mode change reloads the page (profile_preferences.vue), which is
      // the user-visible confirmation, so no toast is needed here.
      const form = this.$el.closest('form');

      if (!form) return;

      if (form.dataset.remote) {
        // If the save fails, revert the selection so the control doesn't keep
        // showing an unsaved value that the server never persisted. Reverting
        // mutates selectedColorModeId directly (no @input event), so it won't
        // re-submit.
        form.addEventListener(
          'ajax:error',
          () => {
            this.selectedColorModeId = previousColorModeId;
          },
          { once: true },
        );
        // Dispatch a native submit event so rails-ujs handles the remote form,
        // mirroring the auto-submit behavior the radio inputs had via profile.js.
        // Avoids a static `@rails/ujs` import, which pulls in jQuery at module load.
        // `bubbles: true` is required: rails-ujs binds its submit handler on
        // `document`, so the event must bubble up to be picked up.
        form.dispatchEvent(new CustomEvent('submit', { bubbles: true, cancelable: true }));
      } else {
        form.submit();
      }
    },
  },
};
</script>

<template>
  <div>
    <input type="hidden" name="user[color_mode_id]" :value="selectedColorModeId" />
    <gl-segmented-control :value="selectedColorModeId" :options="options" @input="onChange" />
  </div>
</template>
