import bundle from '~/packages_and_registries/settings/group/bundle';
import initSearchSettings from '~/search_settings';

bundle();

document.addEventListener('DOMContentLoaded', initSearchSettings);
