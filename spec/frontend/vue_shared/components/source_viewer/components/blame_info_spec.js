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

  it('renders a CommitInfo component for each blame entry', () => {
    expect(findCommitInfoComponents().length).toBe(BLAME_DATA_MOCK.length);
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
