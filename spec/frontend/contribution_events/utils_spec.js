import { TARGET_TYPE_MILESTONE, WORK_ITEM_ISSUE_TYPE_TASK } from '~/contribution_events/constants';
import { getValueByEventTarget } from '~/contribution_events/utils';
import { eventMilestoneCreated, eventTaskCreated } from './utils';

describe('getValueByEventTarget', () => {
  const milestoneValue = 'milestone';
  const taskValue = 'task';
  const fallbackValue = 'fallback';

  const map = {
    [TARGET_TYPE_MILESTONE]: milestoneValue,
    [WORK_ITEM_ISSUE_TYPE_TASK]: taskValue,
    fallback: fallbackValue,
  };

  it.each`
    event                                       | expected
    ${eventMilestoneCreated()}                  | ${milestoneValue}
    ${eventTaskCreated()}                       | ${taskValue}
    ${{ target: { type: 'unsupported type' } }} | ${fallbackValue}
  `('returns $expected when event is $event', ({ event, expected }) => {
    expect(getValueByEventTarget(map, event)).toBe(expected);
  });
});
