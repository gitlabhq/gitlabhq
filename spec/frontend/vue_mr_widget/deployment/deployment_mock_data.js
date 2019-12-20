import { SUCCESS } from '~/vue_merge_request_widget/components/deployment/constants';

const deploymentMockData = {
  id: 15,
  name: 'review/diplo',
  url: '/root/review-apps/environments/15',
  stop_url: '/root/review-apps/environments/15/stop',
  metrics_url: '/root/review-apps/environments/15/deployments/1/metrics',
  metrics_monitoring_url: '/root/review-apps/environments/15/metrics',
  external_url: 'http://gitlab.com.',
  external_url_formatted: 'gitlab',
  deployed_at: '2017-03-22T22:44:42.258Z',
  deployed_at_formatted: 'Mar 22, 2017 10:44pm',
  details: {},
  status: SUCCESS,
  changes: [
    {
      path: 'index.html',
      external_url: 'http://root-master-patch-91341.volatile-watch.surge.sh/index.html',
    },
    {
      path: 'imgs/gallery.html',
      external_url: 'http://root-master-patch-91341.volatile-watch.surge.sh/imgs/gallery.html',
    },
    {
      path: 'about/',
      external_url: 'http://root-master-patch-91341.volatile-watch.surge.sh/about/',
    },
  ],
};

export default deploymentMockData;
