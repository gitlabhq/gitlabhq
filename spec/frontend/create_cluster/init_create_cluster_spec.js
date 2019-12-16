import initCreateCluster from '~/create_cluster/init_create_cluster';
import initGkeDropdowns from '~/create_cluster/gke_cluster';
import initGkeNamespace from '~/create_cluster/gke_cluster_namespace';
import PersistentUserCallout from '~/persistent_user_callout';

// This import is loaded dynamically in `init_create_cluster`.
// Let's eager import it here so that the first spec doesn't timeout.
// https://gitlab.com/gitlab-org/gitlab/issues/118499
import '~/create_cluster/eks_cluster';

jest.mock('~/create_cluster/gke_cluster', () => jest.fn());
jest.mock('~/create_cluster/gke_cluster_namespace', () => jest.fn());
jest.mock('~/persistent_user_callout', () => ({
  factory: jest.fn(),
}));

describe('initCreateCluster', () => {
  let document;
  let gon;

  beforeEach(() => {
    document = {
      body: { dataset: {} },
      querySelector: jest.fn(),
    };
    gon = { features: {} };
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe.each`
    pageSuffix                 | page
    ${':clusters:new'}         | ${'project:clusters:new'}
    ${':clusters:create_gcp'}  | ${'groups:clusters:create_gcp'}
    ${':clusters:create_user'} | ${'admin:clusters:create_user'}
  `('when cluster page ends in $pageSuffix', ({ page }) => {
    beforeEach(() => {
      document.body.dataset = { page };

      initCreateCluster(document, gon);
    });

    it('initializes create GKE cluster app', () => {
      expect(initGkeDropdowns).toHaveBeenCalled();
    });

    it('initializes gcp signup offer banner', () => {
      expect(PersistentUserCallout.factory).toHaveBeenCalled();
    });
  });

  describe('when creating a project level cluster', () => {
    it('initializes gke namespace app', () => {
      document.body.dataset.page = 'project:clusters:new';

      initCreateCluster(document, gon);

      expect(initGkeNamespace).toHaveBeenCalled();
    });
  });

  describe.each`
    clusterLevel        | page
    ${'group level'}    | ${'groups:clusters:new'}
    ${'instance level'} | ${'admin:clusters:create_gcp'}
  `('when creating a $clusterLevel cluster', ({ page }) => {
    it('does not initialize gke namespace app', () => {
      document.body.dataset = { page };

      initCreateCluster(document, gon);

      expect(initGkeNamespace).not.toHaveBeenCalled();
    });
  });
});
