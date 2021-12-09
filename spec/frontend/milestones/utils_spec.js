import { useFakeDate } from 'helpers/fake_date';
import { sortMilestonesByDueDate } from '~/milestones/utils';

describe('sortMilestonesByDueDate', () => {
  useFakeDate(2021, 6, 22);
  const mockMilestones = [
    {
      id: 2,
    },
    {
      id: 1,
      dueDate: '2021-01-01',
    },
    {
      id: 4,
      dueDate: '2021-02-01',
      expired: true,
    },
    {
      id: 3,
      dueDate: `2021-08-01`,
    },
  ];

  describe('sorts milestones', () => {
    it('expired milestones are kept at the bottom of the list', () => {
      const sortedMilestones = [...mockMilestones].sort(sortMilestonesByDueDate);

      expect(sortedMilestones[2].id).toBe(mockMilestones[1].id); // milestone with id `1` is expired
      expect(sortedMilestones[3].id).toBe(mockMilestones[2].id); // milestone with id `4` is expired
    });

    it('milestones with closest due date are kept at the top of the list', () => {
      const sortedMilestones = [...mockMilestones].sort(sortMilestonesByDueDate);

      // milestone with id `3` & 2021-08-01 is closest to current date i.e. 2021-07-22
      expect(sortedMilestones[0].id).toBe(mockMilestones[3].id);
    });

    it('milestones with no due date are kept between milestones with closest due date and expired milestones', () => {
      const sortedMilestones = [...mockMilestones].sort(sortMilestonesByDueDate);

      // milestone with id `2` has no due date
      expect(sortedMilestones[1].id).toBe(mockMilestones[0].id);
    });
  });
});
