import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { setHTMLFixture } from 'helpers/fixtures';
import CommitInfo from '~/repository/components/commit_info.vue';
import BlameInfo from '~/vue_shared/components/source_viewer/components/blame_info.vue';
import * as utils from '~/vue_shared/components/source_viewer/utils';
import { SOURCE_CODE_CONTENT_MOCK, BLAME_DATA_MOCK } from '../mock_data';

describe('BlameInfo component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(BlameInfo, {
      propsData: { blameData: BLAME_DATA_MOCK },
    });
  };

  beforeEach(() => {
    setHTMLFixture(SOURCE_CODE_CONTENT_MOCK);
    jest.spyOn(utils, 'toggleBlameClasses');
    createComponent();
  });

  const findCommitInfoComponents = () => wrapper.findAllComponents(CommitInfo);

  it('adds the necessary classes to the DOM', () => {
    expect(utils.toggleBlameClasses).toHaveBeenCalledWith(BLAME_DATA_MOCK, true);
  });

  it('renders a CommitInfo component for each blame entry', () => {
    expect(findCommitInfoComponents().length).toBe(BLAME_DATA_MOCK.length);
  });

  it.each(BLAME_DATA_MOCK)(
    'sets the correct data and positioning for the commitInfo',
    ({ lineno, commit, index }) => {
      const commitInfoComponent = findCommitInfoComponents().at(index);

      expect(commitInfoComponent.props('commit')).toEqual(commit);
      expect(commitInfoComponent.element.style.top).toBe(utils.calculateBlameOffset(lineno));
    },
  );

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

  describe('when component is destroyed', () => {
    beforeEach(() => wrapper.destroy());

    it('resets the DOM to its original state', () => {
      expect(utils.toggleBlameClasses).toHaveBeenCalledWith(BLAME_DATA_MOCK, false);
    });
  });
});
