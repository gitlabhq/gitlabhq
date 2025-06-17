import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { helpPagePath } from '~/helpers/help_page_helper';
import GroupListItemDelayedDeletionModalFooter from '~/vue_shared/components/groups_list/group_list_item_delayed_deletion_modal_footer.vue';
import { groups } from 'jest/vue_shared/components/groups_list/mock_data';

describe('GroupListItemDelayedDeletionModalFooter', () => {
  let wrapper;

  const [group] = groups;
  const MOCK_PERM_DELETION_DATE = '2024-03-31';
  const HELP_PATH = helpPagePath('user/group/_index', {
    anchor: 'restore-a-group',
  });

  const defaultProps = {
    group,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(GroupListItemDelayedDeletionModalFooter, {
      propsData: { ...defaultProps, ...props },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findDelayedDeletionModalFooter = () => wrapper.findByTestId('delayed-delete-modal-footer');
  const findGlLink = () => wrapper.findComponent(GlLink);

  describe.each`
    markedForDeletionOn | footer                                                                        | link
    ${null}             | ${`This group can be restored until ${MOCK_PERM_DELETION_DATE}. Learn more.`} | ${HELP_PATH}
    ${'2024-03-24'}     | ${false}                                                                      | ${false}
  `(
    'when group.markedForDeletionOn is $markedForDeletionOn',
    ({ markedForDeletionOn, footer, link }) => {
      beforeEach(() => {
        createComponent({
          props: {
            group: {
              ...group,
              markedForDeletionOn,
              permanentDeletionDate: MOCK_PERM_DELETION_DATE,
            },
          },
        });
      });

      it(`does ${footer ? 'render' : 'not render'} the delayed deletion modal footer`, () => {
        expect(
          findDelayedDeletionModalFooter().exists() && findDelayedDeletionModalFooter().text(),
        ).toBe(footer);
        expect(findGlLink().exists() && findGlLink().attributes('href')).toBe(link);
      });
    },
  );
});
