import { readonly, ref } from 'vue';

// In-memory session state for the planning view.
const allItemsFilters = ref(null);
const savedViewFilterTokens = ref({});

export const planningViewAllItemsFilters = readonly(allItemsFilters);

export const setPlanningViewAllItemsFilters = (filters) => {
  allItemsFilters.value = filters;
};

export const getSavedViewSessionFilters = (viewId) => savedViewFilterTokens.value[viewId];

export const setSavedViewSessionFilters = (viewId, tokens) => {
  savedViewFilterTokens.value = {
    ...savedViewFilterTokens.value,
    [viewId]: [...tokens],
  };
};

// currently only used as a test helper, not included in prod code.
export const resetPlanningViewState = () => {
  allItemsFilters.value = null;
  savedViewFilterTokens.value = {};
};
