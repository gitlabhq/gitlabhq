import { getFormattedItem } from '~/super_sidebar/components/global_search/utils';
import {
  LARGE_AVATAR_PX,
  SMALL_AVATAR_PX,
} from '~/super_sidebar/components/global_search/constants';
import {
  GROUPS_CATEGORY,
  PROJECTS_CATEGORY,
  MERGE_REQUEST_CATEGORY,
  ISSUES_CATEGORY,
  RECENT_EPICS_CATEGORY,
  USERS_CATEGORY,
} from '~/vue_shared/global_search/constants';

describe('getFormattedItem', () => {
  describe.each`
    item                                                                                                              | avatarSize         | searchContext                            | entityId     | entityName    | trackingLabel
    ${{ category: PROJECTS_CATEGORY, label: 'project1' }}                                                             | ${LARGE_AVATAR_PX} | ${{ project: { id: 29 } }}               | ${29}        | ${'project1'} | ${'projects'}
    ${{ category: GROUPS_CATEGORY, label: 'project1' }}                                                               | ${LARGE_AVATAR_PX} | ${{ group: { id: 12 } }}                 | ${12}        | ${'project1'} | ${'groups'}
    ${{ category: 'Help', label: 'project1' }}                                                                        | ${SMALL_AVATAR_PX} | ${null}                                  | ${undefined} | ${'project1'} | ${'help'}
    ${{ category: 'Settings', label: 'project1' }}                                                                    | ${SMALL_AVATAR_PX} | ${null}                                  | ${undefined} | ${'project1'} | ${'settings'}
    ${{ category: GROUPS_CATEGORY, value: 'group1', label: 'Group 1' }}                                               | ${LARGE_AVATAR_PX} | ${{ group: { id: 1, name: 'test1' } }}   | ${1}         | ${'group1'}   | ${'groups'}
    ${{ category: PROJECTS_CATEGORY, value: 'group2', label: 'Group2' }}                                              | ${LARGE_AVATAR_PX} | ${{ project: { id: 2, name: 'test2' } }} | ${2}         | ${'group2'}   | ${'projects'}
    ${{ category: ISSUES_CATEGORY }}                                                                                  | ${SMALL_AVATAR_PX} | ${{ project: { id: 3, name: 'test3' } }} | ${3}         | ${'test3'}    | ${'recent_issues'}
    ${{ category: MERGE_REQUEST_CATEGORY }}                                                                           | ${SMALL_AVATAR_PX} | ${{ project: { id: 4, name: 'test4' } }} | ${4}         | ${'test4'}    | ${'recent_merge_requests'}
    ${{ category: RECENT_EPICS_CATEGORY }}                                                                            | ${SMALL_AVATAR_PX} | ${{ group: { id: 5, name: 'test5' } }}   | ${5}         | ${'test5'}    | ${'recent_epics'}
    ${{ category: GROUPS_CATEGORY, group_id: 6, group_name: 'test6' }}                                                | ${LARGE_AVATAR_PX} | ${null}                                  | ${6}         | ${'test6'}    | ${'groups'}
    ${{ category: PROJECTS_CATEGORY, project_id: 7, project_name: 'test7' }}                                          | ${LARGE_AVATAR_PX} | ${null}                                  | ${7}         | ${'test7'}    | ${'projects'}
    ${{ category: ISSUES_CATEGORY, project_id: 8, project_name: 'test8' }}                                            | ${SMALL_AVATAR_PX} | ${null}                                  | ${8}         | ${'test8'}    | ${'recent_issues'}
    ${{ category: MERGE_REQUEST_CATEGORY, project_id: 9, project_name: 'test9' }}                                     | ${SMALL_AVATAR_PX} | ${null}                                  | ${9}         | ${'test9'}    | ${'recent_merge_requests'}
    ${{ category: RECENT_EPICS_CATEGORY, group_id: 10, group_name: 'test10' }}                                        | ${SMALL_AVATAR_PX} | ${null}                                  | ${10}        | ${'test10'}   | ${'recent_epics'}
    ${{ category: GROUPS_CATEGORY, group_id: 11, group_name: 'test11' }}                                              | ${LARGE_AVATAR_PX} | ${{ group: { id: 1, name: 'test1' } }}   | ${11}        | ${'test11'}   | ${'groups'}
    ${{ category: PROJECTS_CATEGORY, project_id: 12, project_name: 'test12' }}                                        | ${LARGE_AVATAR_PX} | ${{ project: { id: 2, name: 'test2' } }} | ${12}        | ${'test12'}   | ${'projects'}
    ${{ category: ISSUES_CATEGORY, project_id: 13, project_name: 'test13' }}                                          | ${SMALL_AVATAR_PX} | ${{ project: { id: 3, name: 'test3' } }} | ${13}        | ${'test13'}   | ${'recent_issues'}
    ${{ category: MERGE_REQUEST_CATEGORY, project_id: 14, project_name: 'test14' }}                                   | ${SMALL_AVATAR_PX} | ${{ project: { id: 4, name: 'test4' } }} | ${14}        | ${'test14'}   | ${'recent_merge_requests'}
    ${{ category: RECENT_EPICS_CATEGORY, group_id: 15, group_name: 'test15' }}                                        | ${SMALL_AVATAR_PX} | ${{ group: { id: 5, name: 'test5' } }}   | ${15}        | ${'test15'}   | ${'recent_epics'}
    ${{ category: USERS_CATEGORY, group_id: 15, group_name: 'test15', name: 'text person', id: 15, label: 'test15' }} | ${SMALL_AVATAR_PX} | ${{ group: { id: 5, name: 'test5' } }}   | ${15}        | ${'test15'}   | ${'users'}
  `(
    'formats the item',
    ({ item, avatarSize, searchContext, entityId, entityName, trackingLabel }) => {
      describe(`when item is ${JSON.stringify(item)}`, () => {
        let formattedItem;
        beforeEach(() => {
          formattedItem = getFormattedItem(item, searchContext);
        });

        it(`should set text to ${item.value || item.label}`, () => {
          expect(formattedItem.text).toBe(item.value || item.label || item.name);
        });

        it(`should set avatarSize to ${avatarSize}`, () => {
          expect(formattedItem.avatar_size).toBe(avatarSize);
        });

        it(`should set avatar entityId to ${entityId}`, () => {
          expect(formattedItem.entity_id).toBe(entityId);
        });

        it(`should set avatar entityName to ${entityName}`, () => {
          expect(formattedItem.entity_name).toBe(entityName);
        });

        it('should add tracking label', () => {
          expect(formattedItem.extraAttrs).toEqual({
            'data-track-action': 'click_command_palette_item',
            'data-track-label': trackingLabel,
          });
        });
      });
    },
  );
});
