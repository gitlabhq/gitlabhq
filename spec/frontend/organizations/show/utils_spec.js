import { buildDisplayListboxItem } from '~/organizations/show/utils';
import { SORT_CREATED_AT, RESOURCE_TYPE_PROJECTS } from '~/organizations/shared/constants';

describe('buildDisplayListboxItem', () => {
  it('returns list item in correct format', () => {
    const text = 'Recently created projects';

    expect(
      buildDisplayListboxItem({
        sortName: SORT_CREATED_AT,
        resourceType: RESOURCE_TYPE_PROJECTS,
        text,
      }),
    ).toEqual({
      sortName: SORT_CREATED_AT,
      text,
      value: 'created_at_projects',
    });
  });
});
