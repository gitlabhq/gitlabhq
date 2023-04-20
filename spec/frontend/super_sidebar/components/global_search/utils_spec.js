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
} from '~/vue_shared/global_search/constants';

describe('getFormattedItem', () => {
  describe.each`
    item                                                                            | avatarSize         | searchContext                            | entityId     | entityName
    ${{ category: PROJECTS_CATEGORY, label: 'project1' }}                           | ${LARGE_AVATAR_PX} | ${{ project: { id: 29 } }}               | ${29}        | ${'project1'}
    ${{ category: GROUPS_CATEGORY, label: 'project1' }}                             | ${LARGE_AVATAR_PX} | ${{ group: { id: 12 } }}                 | ${12}        | ${'project1'}
    ${{ category: 'Help', label: 'project1' }}                                      | ${SMALL_AVATAR_PX} | ${null}                                  | ${undefined} | ${'project1'}
    ${{ category: 'Settings', label: 'project1' }}                                  | ${SMALL_AVATAR_PX} | ${null}                                  | ${undefined} | ${'project1'}
    ${{ category: GROUPS_CATEGORY, value: 'group1', label: 'Group 1' }}             | ${LARGE_AVATAR_PX} | ${{ group: { id: 1, name: 'test1' } }}   | ${1}         | ${'group1'}
    ${{ category: PROJECTS_CATEGORY, value: 'group2', label: 'Group2' }}            | ${LARGE_AVATAR_PX} | ${{ project: { id: 2, name: 'test2' } }} | ${2}         | ${'group2'}
    ${{ category: ISSUES_CATEGORY }}                                                | ${SMALL_AVATAR_PX} | ${{ project: { id: 3, name: 'test3' } }} | ${3}         | ${'test3'}
    ${{ category: MERGE_REQUEST_CATEGORY }}                                         | ${SMALL_AVATAR_PX} | ${{ project: { id: 4, name: 'test4' } }} | ${4}         | ${'test4'}
    ${{ category: RECENT_EPICS_CATEGORY }}                                          | ${SMALL_AVATAR_PX} | ${{ group: { id: 5, name: 'test5' } }}   | ${5}         | ${'test5'}
    ${{ category: GROUPS_CATEGORY, group_id: 6, group_name: 'test6' }}              | ${LARGE_AVATAR_PX} | ${null}                                  | ${6}         | ${'test6'}
    ${{ category: PROJECTS_CATEGORY, project_id: 7, project_name: 'test7' }}        | ${LARGE_AVATAR_PX} | ${null}                                  | ${7}         | ${'test7'}
    ${{ category: ISSUES_CATEGORY, project_id: 8, project_name: 'test8' }}          | ${SMALL_AVATAR_PX} | ${null}                                  | ${8}         | ${'test8'}
    ${{ category: MERGE_REQUEST_CATEGORY, project_id: 9, project_name: 'test9' }}   | ${SMALL_AVATAR_PX} | ${null}                                  | ${9}         | ${'test9'}
    ${{ category: RECENT_EPICS_CATEGORY, group_id: 10, group_name: 'test10' }}      | ${SMALL_AVATAR_PX} | ${null}                                  | ${10}        | ${'test10'}
    ${{ category: GROUPS_CATEGORY, group_id: 11, group_name: 'test11' }}            | ${LARGE_AVATAR_PX} | ${{ group: { id: 1, name: 'test1' } }}   | ${11}        | ${'test11'}
    ${{ category: PROJECTS_CATEGORY, project_id: 12, project_name: 'test12' }}      | ${LARGE_AVATAR_PX} | ${{ project: { id: 2, name: 'test2' } }} | ${12}        | ${'test12'}
    ${{ category: ISSUES_CATEGORY, project_id: 13, project_name: 'test13' }}        | ${SMALL_AVATAR_PX} | ${{ project: { id: 3, name: 'test3' } }} | ${13}        | ${'test13'}
    ${{ category: MERGE_REQUEST_CATEGORY, project_id: 14, project_name: 'test14' }} | ${SMALL_AVATAR_PX} | ${{ project: { id: 4, name: 'test4' } }} | ${14}        | ${'test14'}
    ${{ category: RECENT_EPICS_CATEGORY, group_id: 15, group_name: 'test15' }}      | ${SMALL_AVATAR_PX} | ${{ group: { id: 5, name: 'test5' } }}   | ${15}        | ${'test15'}
  `('formats the item', ({ item, avatarSize, searchContext, entityId, entityName }) => {
    describe(`when item is ${JSON.stringify(item)}`, () => {
      let formattedItem;
      beforeEach(() => {
        formattedItem = getFormattedItem(item, searchContext);
      });

      it(`should set text to ${item.value || item.label}`, () => {
        expect(formattedItem.text).toBe(item.value || item.label);
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
    });
  });
});
