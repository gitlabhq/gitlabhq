import NamespaceSelect from '~/namespace_select';
import ProjectsList from '~/projects_list';

new ProjectsList(); // eslint-disable-line no-new

document
  .querySelectorAll('.js-namespace-select')
  .forEach((dropdown) => new NamespaceSelect({ dropdown }));
