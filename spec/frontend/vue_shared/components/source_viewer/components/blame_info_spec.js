import { nextTick } from 'vue';
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

  describe('commitInfo component styling', () => {
    const borderTopClassName = 'gl-border-t';

    it('does not add a top border for the first entry', () => {
      expect(findCommitInfoComponents().at(0).element.classList).not.toContain(borderTopClassName);
    });

    it('add a top border for the rest of the entries', () => {
      expect(findCommitInfoComponents().at(1).element.classList).toContain(borderTopClassName);
      expect(findCommitInfoComponents().at(2).element.classList).toContain(borderTopClassName);
    });
  });
});
