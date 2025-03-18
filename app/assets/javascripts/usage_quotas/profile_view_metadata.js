import { getNamespaceStorageTabMetadata } from './storage/namespace/tab_metadata';
import { mountUsageQuotasApp } from './utils';

const usageQuotasTabsMetadata = [getNamespaceStorageTabMetadata()].filter(Boolean);

export default () => mountUsageQuotasApp(usageQuotasTabsMetadata);
