import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitInfo from '~/repository/components/commit_info.vue';
import BlameInfo from '~/vue_shared/components/source_viewer/components/blame_info.vue';
import { BLAME_DATA_MOCK } from '../mock_data';

describe('BlameInfo component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(BlameInfo, {
      propsData: {
        blameInfo: BLAME_DATA_MOCK,
        projectPath: 'gitlab-org/gitlab',
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findCommitInfoComponents = () => wrapper.findAllComponents(CommitInfo);

  const findBlameWrappers = () => wrapper.findAll('.blame-commit-wrapper');

  it('renders a CommitInfo component for each blame entry', () => {
    expect(findCommitInfoComponents()).toHaveLength(BLAME_DATA_MOCK.length);
  });

  it.each(BLAME_DATA_MOCK)(
    'sets the correct data and positioning for the commitInfo',
    ({ commit, index, blameOffset, previousPath }) => {
      const commitInfoComponent = findCommitInfoComponents().at(index);

      expect(commitInfoComponent.props('commit')).toEqual(commit);
      expect(commitInfoComponent.props('previousPath')).toBe(previousPath);
      expect(commitInfoComponent.props('projectPath')).toBe('gitlab-org/gitlab');
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
});
