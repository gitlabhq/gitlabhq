import { routeForWorkItemTypeName } from '~/work_items/router/utils';

describe('routeForWorkItemTypeName', () => {
  it.each`
    workItemTypeName | routeName
    ${'issue'}       | ${'issues'}
    ${'epic'}        | ${'epics'}
    ${'Issue'}       | ${'issues'}
    ${'Epic'}        | ${'epics'}
    ${'task'}        | ${'work_items'}
    ${'objective'}   | ${'work_items'}
    ${undefined}     | ${'work_items'}
  `('returns $routeName when passed $workItemTypeName', ({ routeName, workItemTypeName }) => {
    expect(routeForWorkItemTypeName(workItemTypeName)).toBe(routeName);
  });
});
