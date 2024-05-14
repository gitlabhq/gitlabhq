import { PROFILE_VIEW_TYPE } from '~/usage_quotas/constants';
import { getStorageTabMetadata } from '~/usage_quotas/storage/tab_metadata';

export const usageQuotasTabsMetadata = [
  getStorageTabMetadata({ viewType: PROFILE_VIEW_TYPE }),
].filter(Boolean);
