import { transformNotFilters } from '~/boards/boards_util';

describe('transformNotFilters', () => {
  const filters = {
    'not[labelName]': ['label'],
    'not[assigneeUsername]': 'assignee',
  };

  it('formats not filters, transforms epicId to fullEpicId', () => {
    const result = transformNotFilters(filters);

    expect(result).toEqual({
      labelName: ['label'],
      assigneeUsername: 'assignee',
    });
  });
});
