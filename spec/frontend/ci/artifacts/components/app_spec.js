import { GlSkeletonLoader } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import ArtifactsApp from '~/ci/artifacts/components/app.vue';
import JobArtifactsTable from '~/ci/artifacts/components/job_artifacts_table.vue';
import getBuildArtifactsSizeQuery from '~/ci/artifacts/graphql/queries/get_build_artifacts_size.query.graphql';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { PAGE_TITLE, TOTAL_ARTIFACTS_SIZE, SIZE_UNKNOWN } from '~/ci/artifacts/constants';

const TEST_BUILD_ARTIFACTS_SIZE = 1024;
const TEST_PROJECT_PATH = 'project/path';
const TEST_PROJECT_ID = 'gid://gitlab/Project/22';

const createBuildArtifactsSizeResponse = ({
  buildArtifactsSize = TEST_BUILD_ARTIFACTS_SIZE,
  nullStatistics = false,
}) => ({
  data: {
    project: {
      __typename: 'Project',
      id: TEST_PROJECT_ID,
      statistics: nullStatistics
        ? null
        : {
            __typename: 'ProjectStatistics',
            buildArtifactsSize,
          },
    },
  },
});

Vue.use(VueApollo);

describe('ArtifactsApp component', () => {
  let wrapper;
  let apolloProvider;
  let getBuildArtifactsSizeSpy;

  const findTitle = () => wrapper.findByTestId('page-heading');
  const findBuildArtifactsSize = () => wrapper.findByTestId('build-artifacts-size');
  const findJobArtifactsTable = () => wrapper.findComponent(JobArtifactsTable);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  const createComponent = () => {
    wrapper = shallowMountExtended(ArtifactsApp, {
      provide: { projectPath: 'project/path' },
      apolloProvider,
      stubs: {
        PageHeading,
      },
    });
  };

  beforeEach(() => {
    getBuildArtifactsSizeSpy = jest.fn();

    apolloProvider = createMockApollo([[getBuildArtifactsSizeQuery, getBuildArtifactsSizeSpy]]);
  });

  describe('when loading', () => {
    beforeEach(() => {
      // Promise that never resolves so it's always loading
      getBuildArtifactsSizeSpy.mockReturnValue(new Promise(() => {}));

      createComponent();
    });

    it('shows the page title', () => {
      expect(findTitle().text()).toBe(PAGE_TITLE);
    });

    it('shows a skeleton while loading the artifacts size', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('shows the job artifacts table', () => {
      expect(findJobArtifactsTable().exists()).toBe(true);
    });

    it('does not show message', () => {
      expect(findBuildArtifactsSize().text()).toBe('');
    });

    it('calls apollo query', () => {
      expect(getBuildArtifactsSizeSpy).toHaveBeenCalledWith({ projectPath: TEST_PROJECT_PATH });
    });
  });

  describe.each`
    buildArtifactsSize           | nullStatistics | expectedText
    ${TEST_BUILD_ARTIFACTS_SIZE} | ${false}       | ${numberToHumanSize(TEST_BUILD_ARTIFACTS_SIZE)}
    ${null}                      | ${false}       | ${SIZE_UNKNOWN}
    ${null}                      | ${true}        | ${SIZE_UNKNOWN}
  `(
    'when buildArtifactsSize is $buildArtifactsSize',
    ({ buildArtifactsSize, nullStatistics, expectedText }) => {
      beforeEach(async () => {
        getBuildArtifactsSizeSpy.mockResolvedValue(
          createBuildArtifactsSizeResponse({ buildArtifactsSize, nullStatistics }),
        );

        createComponent();

        await waitForPromises();
      });

      it('hides loader', () => {
        expect(findSkeletonLoader().exists()).toBe(false);
      });

      it('shows the size', () => {
        expect(findBuildArtifactsSize().text()).toMatchInterpolatedText(
          `${TOTAL_ARTIFACTS_SIZE} ${expectedText}`,
        );
      });
    },
  );
});
