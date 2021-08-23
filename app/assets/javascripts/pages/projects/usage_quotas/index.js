import LinkedTabs from '~/lib/utils/bootstrap_linked_tabs';
import storageCounter from '~/projects/storage_counter';
import initSearchSettings from '~/search_settings';

const initLinkedTabs = () => {
  if (!document.querySelector('.js-usage-quota-tabs')) {
    return false;
  }

  return new LinkedTabs({
    defaultAction: '#storage-quota-tab',
    parentEl: '.js-usage-quota-tabs',
    hashedTabs: true,
  });
};

const initVueApp = () => {
  storageCounter('js-project-storage-count-app');
};

initVueApp();
initLinkedTabs();
initSearchSettings();
