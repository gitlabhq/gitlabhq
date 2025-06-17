import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { isNarrowScreenMediaQuery } from '~/lib/utils/css_utils';

export const useViewport = defineStore('viewportStore', () => {
  const isNarrowScreen = ref(false);

  const updateIsNarrow = (matches) => {
    isNarrowScreen.value = matches;
  };

  const reset = () => {
    isNarrowScreen.value = false;
  };

  const query = isNarrowScreenMediaQuery();
  updateIsNarrow(query.matches);

  query.addEventListener('change', (event) => {
    updateIsNarrow(event.matches);
  });

  return {
    // used only for testing
    updateIsNarrow,
    // used only for testing
    reset,
    isNarrowScreen: computed(() => isNarrowScreen.value),
  };
});
