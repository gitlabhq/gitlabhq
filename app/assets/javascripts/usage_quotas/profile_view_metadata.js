import { PROFILE_VIEW_TYPE } from '~/usage_quotas/constants';
import { getStorageTabMetadata } from '~/usage_quotas/storage/tab_metadata';
import { mountUsageQuotasApp } from './utils';

const usageQuotasTabsMetadata = [getStorageTabMetadata({ viewType: PROFILE_VIEW_TYPE })].filter(
  Boolean,
);

export default () => mountUsageQuotasApp(usageQuotasTabsMetadata);
