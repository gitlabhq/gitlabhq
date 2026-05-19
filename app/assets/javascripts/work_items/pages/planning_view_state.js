import { readonly, ref } from 'vue';

// In-memory session state for the planning view.
const allItemsFilters = ref(null);
const savedViewFilterTokens = ref({});

export const planningViewAllItemsFilters = readonly(allItemsFilters);
export const planningViewSavedViewFilterTokens = readonly(savedViewFilterTokens);

export const setPlanningViewAllItemsFilters = (filters) => {
  allItemsFilters.value = filters;
};

export const setPlanningViewSavedViewFilterTokens = (tokens) => {
  savedViewFilterTokens.value = tokens;
};
