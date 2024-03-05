import { PROJECT_VIEW_TYPE } from './constants';
import { getStorageTabMetadata } from './storage/tab_metadata';

export const usageQuotasTabsMetadata = [
  getStorageTabMetadata({ viewType: PROJECT_VIEW_TYPE }),
].filter(Boolean);
