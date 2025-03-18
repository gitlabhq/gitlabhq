import { getNamespaceStorageTabMetadata } from './storage/namespace/tab_metadata';
import { getImportTabMetadata } from './import/tab_metadata';
import { mountUsageQuotasApp } from './utils';

const usageQuotasTabsMetadata = [getNamespaceStorageTabMetadata(), getImportTabMetadata()].filter(
  Boolean,
);

export default () => mountUsageQuotasApp(usageQuotasTabsMetadata);
