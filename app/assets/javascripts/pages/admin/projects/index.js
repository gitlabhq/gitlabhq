import ProjectsList from '../../../projects_list';
import NamespaceSelect from '../../../namespace_select';

export default () => {
  new ProjectsList(); // eslint-disable-line no-new

  document.querySelectorAll('.js-namespace-select')
    .forEach(dropdown => new NamespaceSelect({ dropdown }));
};
