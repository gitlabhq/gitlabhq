import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitListApp from '~/projects/commits/components/commit_list_app.vue';
import CommitListHeader from '~/projects/commits/components/commit_list_header.vue';
import CommitListItem from '~/projects/commits/components/commit_list_item.vue';
import { mockCommits } from 'jest/projects/commits/components/mock_data';

describe('Commit List App', () => {
  let wrapper;

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(CommitListApp, {
      provide: {
        ...provide,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findCommitHeader = () => wrapper.findComponent(CommitListHeader);
  const findDailyCommits = () => wrapper.findAllByTestId('daily-commits');
  const findTimeElements = () => wrapper.findAll('time');

  describe('commit header', () => {
    it('renders the commit header component', () => {
      expect(findCommitHeader().exists()).toBe(true);
    });
  });

  describe('commits data', () => {
    it('renders the correct number of commits', () => {
      expect(findDailyCommits()).toHaveLength(mockCommits.length);
    });
  });

  describe('commit day rendering', () => {
    it('renders time elements with correct data', () => {
      const timeElements = findTimeElements();
      expect(timeElements).toHaveLength(mockCommits.length);

      const expectedDateText = ['Jun 23, 2025', 'Jun 21, 2025'];

      timeElements.wrappers.forEach((timeElement, index) => {
        expect(timeElement.attributes('datetime')).toBe(mockCommits[index].day);
        expect(timeElement.text()).toBe(expectedDateText[index]);
      });
    });
  });

  describe('commit list items', () => {
    it('passes correct commit data to each commit list item', () => {
      mockCommits.forEach((day, dayIndex) => {
        const dailyCommits = findDailyCommits().at(dayIndex);
        day.dailyCommits.forEach((expectedCommit, commitIndex) => {
          const commitItems = dailyCommits.findAllComponents(CommitListItem);
          expect(commitItems.at(commitIndex).props('commit')).toBe(expectedCommit);
        });
      });
    });
  });
});
