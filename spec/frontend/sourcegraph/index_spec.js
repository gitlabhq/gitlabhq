import initSourcegraph from '~/sourcegraph';

const TEST_SOURCEGRAPH_URL = 'https://sourcegraph.test:9000';
const TEST_GITLAB_URL = 'https://gitlab.example.com/test';
const TEST_ASSET_HOST = 'https://gitlab-assets.example.com/';

describe('~/sourcegraph/index', () => {
  let origGon;

  beforeEach(() => {
    origGon = window.gon;
    window.gon = {
      sourcegraph: {},
      gitlab_url: TEST_GITLAB_URL,
    };
  });

  afterEach(() => {
    document.head.innerHTML = '';
    document.body.innerHTML = '';
    window.gon = origGon;
  });

  const findScript = () => document.querySelector('script');

  it('with no sourcegraph url, does nothing', () => {
    initSourcegraph();

    expect(findScript()).toBeNull();
  });

  describe.each`
    assetHost          | assetsUrl                                           | scriptPath
    ${null}            | ${`${TEST_GITLAB_URL}/assets/webpack/sourcegraph/`} | ${`${TEST_GITLAB_URL}/assets/webpack/sourcegraph/scripts/integration.bundle.js`}
    ${TEST_ASSET_HOST} | ${`${TEST_ASSET_HOST}assets/webpack/sourcegraph/`}  | ${`${TEST_ASSET_HOST}assets/webpack/sourcegraph/scripts/integration.bundle.js`}
  `('loads sourcegraph (assetHost=$assetHost)', ({ assetHost, assetsUrl, scriptPath }) => {
    beforeEach(() => {
      Object.assign(window.gon, {
        sourcegraph: {
          url: TEST_SOURCEGRAPH_URL,
        },
        asset_host: assetHost,
      });

      initSourcegraph();
    });

    it('should add sourcegraph config constants to window', () => {
      expect(window).toMatchObject({
        SOURCEGRAPH_ASSETS_URL: assetsUrl,
        SOURCEGRAPH_URL: TEST_SOURCEGRAPH_URL,
        SOURCEGRAPH_INTEGRATION: 'gitlab-integration',
      });
    });

    it('should add script tag', () => {
      expect(findScript()).toMatchObject({
        src: scriptPath,
        defer: true,
        type: 'application/javascript',
      });
    });
  });
});
