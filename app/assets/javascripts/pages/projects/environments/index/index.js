import initEnvironments from '~/environments/';
import initNewEnvironments from '~/environments/new_index';

let el = document.getElementById('environments-list-view');

if (el) {
  initEnvironments(el);
} else {
  el = document.getElementById('environments-table');
  initNewEnvironments(el);
}
