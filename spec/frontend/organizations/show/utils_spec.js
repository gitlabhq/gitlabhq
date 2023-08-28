import { buildDisplayListboxItem } from '~/organizations/show/utils';
import { RESOURCE_TYPE_PROJECTS } from '~/organizations/constants';
import { FILTER_FREQUENTLY_VISITED } from '~/organizations/show/constants';

describe('buildDisplayListboxItem', () => {
  it('returns list item in correct format', () => {
    const text = 'Frequently visited projects';

    expect(
      buildDisplayListboxItem({
        filter: FILTER_FREQUENTLY_VISITED,
        resourceType: RESOURCE_TYPE_PROJECTS,
        text,
      }),
    ).toEqual({
      text,
      value: 'frequently_visited_projects',
    });
  });
});
