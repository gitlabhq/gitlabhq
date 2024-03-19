import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiResourceAbout from '~/ci/catalog/components/details/ci_resource_about.vue';
import { getTimeago } from '~/lib/utils/datetime_utility';

describe('CiResourceAbout', () => {
  let wrapper;

  const defaultProps = {
    isLoadingSharedData: false,
    isLoadingDetails: false,
    openIssuesCount: 4,
    openMergeRequestsCount: 9,
    latestVersion: {
      id: 1,
      name: 'v1.0.0',
      path: 'path/to/release',
      createdAt: '2022-08-23T17:19:09Z',
    },
    webPath: 'path/to/project',
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(CiResourceAbout, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findProjectLink = () => wrapper.findByText('Go to the project');
  const findIssueCount = () => wrapper.findByText(`${defaultProps.openIssuesCount} issues`);
  const findMergeRequestCount = () =>
    wrapper.findByText(`${defaultProps.openMergeRequestsCount} merge requests`);
  const findLastRelease = () =>
    wrapper.findByText(`Released ${getTimeago().format(defaultProps.latestVersion.createdAt)}`);
  const findAllLoadingItems = () => wrapper.findAllByTestId('skeleton-loading-line');

  // Shared data items are items which gets their data from the index page query.
  const sharedDataItems = [findProjectLink, findLastRelease];
  // additional details items gets their state only when on the details page
  const additionalDetailsItems = [findIssueCount, findMergeRequestCount];
  const allItems = [...sharedDataItems, ...additionalDetailsItems];

  describe('when loading shared data', () => {
    beforeEach(() => {
      createComponent({ props: { isLoadingSharedData: true, isLoadingDetails: true } });
    });

    it('renders all server-side data as loading', () => {
      allItems.forEach((finder) => {
        expect(finder().exists()).toBe(false);
      });

      expect(findAllLoadingItems()).toHaveLength(allItems.length);
    });
  });

  describe('when loading additional details', () => {
    beforeEach(() => {
      createComponent({ props: { isLoadingDetails: true } });
    });

    it('renders only the details query as loading', () => {
      sharedDataItems.forEach((finder) => {
        expect(finder().exists()).toBe(true);
      });

      additionalDetailsItems.forEach((finder) => {
        expect(finder().exists()).toBe(false);
      });

      expect(findAllLoadingItems()).toHaveLength(additionalDetailsItems.length);
    });
  });

  describe('when has loaded', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders project link', () => {
      expect(findProjectLink().exists()).toBe(true);
    });

    it('renders the number of issues opened', () => {
      expect(findIssueCount().exists()).toBe(true);
    });

    it('renders the number of merge requests opened', () => {
      expect(findMergeRequestCount().exists()).toBe(true);
    });

    it('renders the last release date', () => {
      expect(findLastRelease().exists()).toBe(true);
    });

    describe('links', () => {
      it('has the correct project link', () => {
        expect(findProjectLink().attributes('href')).toBe(defaultProps.webPath);
      });

      it('has the correct issues link', () => {
        expect(findIssueCount().attributes('href')).toBe(`${defaultProps.webPath}/issues`);
      });

      it('has the correct merge request link', () => {
        expect(findMergeRequestCount().attributes('href')).toBe(
          `${defaultProps.webPath}/merge_requests`,
        );
      });

      it('has no link for release data', () => {
        expect(findLastRelease().attributes('href')).toBe(undefined);
      });
    });
  });
});
