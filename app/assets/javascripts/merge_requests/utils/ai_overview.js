import { AI_OVERVIEW_EL_ID } from '../constants';

// Only rendered once the user opts into the overview replacement, so its presence is what tells the
// classic Overview apps - notes and the issuable sidebar - to stand down.
export const getAiOverviewEl = () => document.getElementById(AI_OVERVIEW_EL_ID);
