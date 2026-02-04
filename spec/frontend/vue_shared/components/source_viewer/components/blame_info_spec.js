import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlameCommitInfo from '~/vue_shared/components/source_viewer/components/blame_commit_info.vue';
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

  const findBlameCommitInfoComponents = () => wrapper.findAllComponents(BlameCommitInfo);
  const findBlameWrappers = () => wrapper.findAll('.blame-commit-wrapper');

  beforeEach(() => createComponent());

  it('renders a BlameCommitInfo component for each blame entry', () => {
    expect(findBlameCommitInfoComponents()).toHaveLength(BLAME_DATA_MOCK.length);
  });

  it.each(BLAME_DATA_MOCK)(
    'sets the correct data and positioning for blame entry at index $index',
    ({ commit, index, blameOffset, previousPath }) => {
      const blameCommitInfo = findBlameCommitInfoComponents().at(index);

      expect(blameCommitInfo.props('commit')).toEqual(commit);
      expect(blameCommitInfo.props('previousPath')).toBe(previousPath);
      expect(blameCommitInfo.props('projectPath')).toBe('gitlab-org/gitlab');
      expect(blameCommitInfo.element.style.top).toBe(blameOffset);
    },
  );

  describe('blame age indicator', () => {
    it('renders an indicator per each BlameCommitInfo component', () => {
      expect(findBlameWrappers()).toHaveLength(findBlameCommitInfoComponents().length);
    });

    it.each(BLAME_DATA_MOCK.map((_, index) => [index]))(
      'sets the position to the same value as BlameCommitInfo component at index %i',
      (index) => {
        const blameWrapperTop = findBlameWrappers()
          .at(index)
          .element.style.getPropertyValue('--blame-indicator-top');
        const blameCommitInfoTop = findBlameCommitInfoComponents().at(index).element.style.top;

        expect(blameWrapperTop).toBe(blameCommitInfoTop);
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

        expect(findBlameWrappers()).toHaveLength(4);
      });
    });
  });
});
