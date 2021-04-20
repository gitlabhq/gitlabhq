import $ from 'jquery';
import BindInOut from '~/behaviors/bind_in_out';
import initFilePickers from '~/file_pickers';
import Group from '~/group';
import LinkedTabs from '~/lib/utils/bootstrap_linked_tabs';
import GroupPathValidator from './group_path_validator';

new GroupPathValidator(); // eslint-disable-line no-new

BindInOut.initAll();
initFilePickers();

new Group(); // eslint-disable-line no-new

const CONTAINER_SELECTOR = '.group-edit-container .nav-tabs';
const DEFAULT_ACTION = '#create-group-pane';
// eslint-disable-next-line no-new
new LinkedTabs({
  defaultAction: DEFAULT_ACTION,
  parentEl: CONTAINER_SELECTOR,
  hashedTabs: true,
});

if (window.location.hash) {
  $(CONTAINER_SELECTOR).find(`a[href="${window.location.hash}"]`).tab('show');
}
