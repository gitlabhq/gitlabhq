import { getProjectStorageTabMetadata } from './storage/project/tab_metadata';
import { mountUsageQuotasApp } from './utils';

const usageQuotasTabsMetadata = [getProjectStorageTabMetadata()].filter(Boolean);

export default () => mountUsageQuotasApp(usageQuotasTabsMetadata);
