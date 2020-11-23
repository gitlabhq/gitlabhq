import initCreateCluster from '~/create_cluster/init_create_cluster';
import initIntegrationForm from '~/clusters/forms/show/index';

document.addEventListener('DOMContentLoaded', () => {
  initCreateCluster(document, gon);
  initIntegrationForm();
});
