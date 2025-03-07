import { GROUP_VIEW_TYPE } from './constants';
import { getStorageTabMetadata } from './storage/tab_metadata';
import { mountUsageQuotasApp } from './utils';

const usageQuotasTabsMetadata = [getStorageTabMetadata({ viewType: GROUP_VIEW_TYPE })].filter(
  Boolean,
);

export default () => mountUsageQuotasApp(usageQuotasTabsMetadata);
