import { nextTick } from 'vue';
import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitInfo from '~/repository/components/commit_info.vue';
import BlameInfo from '~/vue_shared/components/source_viewer/components/blame_info.vue';
import { BLAME_DATA_MOCK } from '../mock_data';

describe('BlameInfo component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(BlameInfo, {
      propsData: { blameInfo: BLAME_DATA_MOCK },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findCommitInfoComponents = () => wrapper.findAllComponents(CommitInfo);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  const findBlameWrappers = () => wrapper.findAll('.blame-commit-wrapper');

  it('renders a CommitInfo component for each blame entry', () => {
    expect(findCommitInfoComponents()).toHaveLength(BLAME_DATA_MOCK.length);
  });

  it.each(BLAME_DATA_MOCK)(
    'sets the correct data and positioning for the commitInfo',
    ({ commit, commitData, index, blameOffset }) => {
      const commitInfoComponent = findCommitInfoComponents().at(index);

      expect(commitInfoComponent.props('commit')).toEqual(commit);
      expect(commitInfoComponent.props('prevBlameLink')).toBe(commitData?.projectBlameLink || null);
      expect(commitInfoComponent.element.style.top).toBe(blameOffset);
    },
  );

  describe('blame age indicator', () => {
    it('renders an indicator per each commitInfo component', () => {
      expect(findBlameWrappers()).toHaveLength(findCommitInfoComponents().length);
    });

    it.each(BLAME_DATA_MOCK.map((_, index) => [index]))(
      'sets the position to the same value as commitInfo component at index %i',
      (index) => {
        const blameWrapperTop = findBlameWrappers()
          .at(index)
          .element.style.getPropertyValue('--blame-indicator-top');
        const commitInfoTop = findCommitInfoComponents().at(index).element.style.top;

        expect(blameWrapperTop).toBe(commitInfoTop);
        expect(blameWrapperTop).toBe(BLAME_DATA_MOCK[index].blameOffset);
      },
    );

    it('sets correct blame indicator colors based on age class', () => {
      const firstWrapper = findBlameWrappers().at(0);
      const expectedColor = 'var(--gl-color-data-blue-50)'; // blame-commit-age-9

      expect(firstWrapper.element.style.getPropertyValue('--blame-indicator-color')).toBe(
        expectedColor,
      );
    });

    it('hides blame indicators from screen readers', () => {
      const wrappers = findBlameWrappers();
      for (let i = 0; i < wrappers.length; i += 1) {
        expect(wrappers.at(i).attributes('aria-hidden')).toBe('true');
      }
    });

    describe('when blameInfo changes', () => {
      const extendedBlameData = [
        ...BLAME_DATA_MOCK,
        { lineno: 4, commit: { author: 'John', sha: 'jkl' }, index: 3, blameOffset: '3px' },
      ];

      it('recalculates heights when new blame data is added', async () => {
        expect(findBlameWrappers()).toHaveLength(3);
        // setProps used to test reactivity of the component
        await wrapper.setProps({ blameInfo: extendedBlameData });
        await nextTick();

        const wrappers = findBlameWrappers();

        expect(wrappers).toHaveLength(4);
      });
    });
  });

  describe('skeleton loader', () => {
    it('renders skeleton loaders when loading with no data', () => {
      wrapper = shallowMountExtended(BlameInfo, {
        propsData: {
          blameInfo: [],
          isBlameLoading: true,
        },
      });

      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findCommitInfoComponents()).toHaveLength(0);
    });

    it('does not render skeleton loader when loading is false', () => {
      wrapper = shallowMountExtended(BlameInfo, {
        propsData: {
          blameInfo: BLAME_DATA_MOCK,
          isBlameLoading: false,
        },
      });

      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findCommitInfoComponents()).toHaveLength(BLAME_DATA_MOCK.length);
    });

    it('does not render skeleton loader when data exists even if loading', () => {
      wrapper = shallowMountExtended(BlameInfo, {
        propsData: {
          blameInfo: BLAME_DATA_MOCK,
          isBlameLoading: true,
        },
      });

      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findCommitInfoComponents()).toHaveLength(BLAME_DATA_MOCK.length);
    });
  });
});
