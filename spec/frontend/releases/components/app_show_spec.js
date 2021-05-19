import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { getJSONFixture } from 'helpers/fixtures';
import createMockApollo from 'helpers/mock_apollo_helper';
import createFlash from '~/flash';
import ReleaseShowApp from '~/releases/components/app_show.vue';
import ReleaseBlock from '~/releases/components/release_block.vue';
import ReleaseSkeletonLoader from '~/releases/components/release_skeleton_loader.vue';
import oneReleaseQuery from '~/releases/graphql/queries/one_release.query.graphql';

jest.mock('~/flash');

const oneReleaseQueryResponse = getJSONFixture(
  'graphql/releases/graphql/queries/one_release.query.graphql.json',
);

Vue.use(VueApollo);

const EXPECTED_ERROR_MESSAGE = 'Something went wrong while getting the release details.';
const MOCK_FULL_PATH = 'project/full/path';
const MOCK_TAG_NAME = 'test-tag-name';

describe('Release show component', () => {
  let wrapper;

  const createComponent = ({ apolloProvider }) => {
    wrapper = shallowMount(ReleaseShowApp, {
      provide: {
        fullPath: MOCK_FULL_PATH,
        tagName: MOCK_TAG_NAME,
      },
      apolloProvider,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findLoadingSkeleton = () => wrapper.find(ReleaseSkeletonLoader);
  const findReleaseBlock = () => wrapper.find(ReleaseBlock);

  const expectLoadingIndicator = () => {
    it('renders a loading indicator', () => {
      expect(findLoadingSkeleton().exists()).toBe(true);
    });
  };

  const expectNoLoadingIndicator = () => {
    it('does not render a loading indicator', () => {
      expect(findLoadingSkeleton().exists()).toBe(false);
    });
  };

  const expectNoFlash = () => {
    it('does not show a flash message', () => {
      expect(createFlash).not.toHaveBeenCalled();
    });
  };

  const expectFlashWithMessage = (message) => {
    it(`shows a flash message that reads "${message}"`, () => {
      expect(createFlash).toHaveBeenCalledTimes(1);
      expect(createFlash).toHaveBeenCalledWith({
        message,
        captureError: true,
        error: expect.any(Error),
      });
    });
  };

  const expectReleaseBlock = () => {
    it('renders a release block', () => {
      expect(findReleaseBlock().exists()).toBe(true);
    });
  };

  const expectNoReleaseBlock = () => {
    it('does not render a release block', () => {
      expect(findReleaseBlock().exists()).toBe(false);
    });
  };

  describe('GraphQL query variables', () => {
    const queryHandler = jest.fn().mockResolvedValueOnce(oneReleaseQueryResponse);

    beforeEach(() => {
      const apolloProvider = createMockApollo([[oneReleaseQuery, queryHandler]]);

      createComponent({ apolloProvider });
    });

    it('builds a GraphQL with the expected variables', () => {
      expect(queryHandler).toHaveBeenCalledTimes(1);
      expect(queryHandler).toHaveBeenCalledWith({
        fullPath: MOCK_FULL_PATH,
        tagName: MOCK_TAG_NAME,
      });
    });
  });

  describe('when the component is loading data', () => {
    beforeEach(() => {
      const apolloProvider = createMockApollo([
        [oneReleaseQuery, jest.fn().mockReturnValueOnce(new Promise(() => {}))],
      ]);

      createComponent({ apolloProvider });
    });

    expectLoadingIndicator();
    expectNoFlash();
    expectNoReleaseBlock();
  });

  describe('when the component has successfully loaded the release', () => {
    beforeEach(() => {
      const apolloProvider = createMockApollo([
        [oneReleaseQuery, jest.fn().mockResolvedValueOnce(oneReleaseQueryResponse)],
      ]);

      createComponent({ apolloProvider });
    });

    expectNoLoadingIndicator();
    expectNoFlash();
    expectReleaseBlock();
  });

  describe('when the request succeeded, but the returned "project" key was null', () => {
    beforeEach(() => {
      const apolloProvider = createMockApollo([
        [oneReleaseQuery, jest.fn().mockResolvedValueOnce({ data: { project: null } })],
      ]);

      createComponent({ apolloProvider });
    });

    expectNoLoadingIndicator();
    expectFlashWithMessage(EXPECTED_ERROR_MESSAGE);
    expectNoReleaseBlock();
  });

  describe('when the request succeeded, but the returned "project.release" key was null', () => {
    beforeEach(() => {
      const apolloProvider = createMockApollo([
        [
          oneReleaseQuery,
          jest.fn().mockResolvedValueOnce({ data: { project: { release: null } } }),
        ],
      ]);

      createComponent({ apolloProvider });
    });

    expectNoLoadingIndicator();
    expectFlashWithMessage(EXPECTED_ERROR_MESSAGE);
    expectNoReleaseBlock();
  });

  describe('when an error occurs while loading the release', () => {
    beforeEach(() => {
      const apolloProvider = createMockApollo([
        [oneReleaseQuery, jest.fn().mockRejectedValueOnce('An error occurred!')],
      ]);

      createComponent({ apolloProvider });
    });

    expectNoLoadingIndicator();
    expectFlashWithMessage(EXPECTED_ERROR_MESSAGE);
    expectNoReleaseBlock();
  });
});
