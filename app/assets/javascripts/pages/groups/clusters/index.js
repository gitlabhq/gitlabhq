import initIntegrationForm from '~/clusters/forms/show/index';
import initCreateCluster from '~/create_cluster/init_create_cluster';

document.addEventListener('DOMContentLoaded', () => {
  initCreateCluster(document, gon);
  initIntegrationForm();
});
