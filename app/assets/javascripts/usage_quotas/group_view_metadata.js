import { __ } from '~/locale';
import NamespaceStorageApp from './storage/components/namespace_storage_app.vue';
import { parseProvideData as parseStorageTabProvideData } from './storage/utils';
import { STORAGE_TAB_METADATA_EL_SELECTOR } from './constants';

export const usageQuotasViewProvideData = {
  ...parseStorageTabProvideData(document.querySelector(STORAGE_TAB_METADATA_EL_SELECTOR)),
};

export const storageTabMetadata = {
  title: __('Storage'),
  component: NamespaceStorageApp,
};

export const usageQuotasTabsMetadata = [storageTabMetadata];
