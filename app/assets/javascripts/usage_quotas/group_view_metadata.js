import { GROUP_VIEW_TYPE } from './constants';
import { getStorageTabMetadata } from './storage/tab_metadata';

export const usageQuotasTabsMetadata = [
  getStorageTabMetadata({ viewType: GROUP_VIEW_TYPE }),
].filter(Boolean);
