import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import GroupListItemDeleteModal from '~/vue_shared/components/groups_list/group_list_item_delete_modal.vue';
import GroupListItemDelayedDeletionModalFooter from '~/vue_shared/components/groups_list/group_list_item_delayed_deletion_modal_footer.vue';
import DangerConfirmModal from '~/vue_shared/components/confirm_danger/confirm_danger_modal.vue';
import { groups } from 'jest/vue_shared/components/groups_list/mock_data';

describe('GroupListItemDeleteModal', () => {
  let wrapper;

  const [group] = groups;

  const MOCK_PERM_DELETION_DATE = '2024-03-31';

  const DELETE_MODAL_BODY_OVERRIDE = `This group is scheduled to be deleted on ${MOCK_PERM_DELETION_DATE}. You are about to delete this group, including its subgroups and projects, immediately. This action cannot be undone.`;
  const DELETE_MODAL_TITLE_OVERRIDE = 'Delete group immediately?';
  const DEFAULT_DELETE_MODAL_TITLE = 'Are you absolutely sure?';

  const defaultProps = {
    modalId: '123',
    phrase: 'mock phrase',
    group,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(GroupListItemDeleteModal, {
      propsData: { ...defaultProps, ...props },
      stubs: {
        GlSprintf,
        DangerConfirmModal: stubComponent(DangerConfirmModal, {
          template: '<div><slot name="modal-body"></slot><slot name="modal-footer"></slot></div>',
        }),
      },
    });
  };

  const findDangerConfirmModal = () => wrapper.findComponent(DangerConfirmModal);
  const findDelayedDeletionModalFooter = () =>
    wrapper.findComponent(GroupListItemDelayedDeletionModalFooter);

  it('renders modal footer', () => {
    createComponent({ props: { visible: true } });

    expect(findDelayedDeletionModalFooter().props('group')).toEqual(group);
  });

  describe('when visible is false', () => {
    beforeEach(() => {
      createComponent({ props: { visible: false } });
    });

    it('does not show modal', () => {
      expect(findDangerConfirmModal().props('visible')).toBe(false);
    });
  });

  describe('delete modal overrides', () => {
    describe.each`
      markedForDeletion | modalTitle                     | modalBody
      ${false}          | ${DEFAULT_DELETE_MODAL_TITLE}  | ${''}
      ${true}           | ${DELETE_MODAL_TITLE_OVERRIDE} | ${DELETE_MODAL_BODY_OVERRIDE}
      ${true}           | ${DELETE_MODAL_TITLE_OVERRIDE} | ${DELETE_MODAL_BODY_OVERRIDE}
    `(
      'when group markedForDeletion is $markedForDeletion',
      ({ markedForDeletion, modalTitle, modalBody }) => {
        beforeEach(() => {
          createComponent({
            props: {
              visible: true,
              group: {
                ...group,
                parent: { id: 1 },
                permanentDeletionDate: MOCK_PERM_DELETION_DATE,
                markedForDeletion,
              },
            },
          });
        });

        it(`${
          modalTitle === DELETE_MODAL_TITLE_OVERRIDE ? 'does' : 'does not'
        } override deletion modal title`, () => {
          expect(findDangerConfirmModal().props('modalTitle')).toBe(modalTitle);
        });

        it(`${modalBody ? 'does' : 'does not'} override deletion modal body`, () => {
          expect(findDangerConfirmModal().text()).toBe(modalBody);
        });
      },
    );
  });

  describe('events', () => {
    describe('deletion modal events', () => {
      beforeEach(() => {
        createComponent({
          props: {
            visible: true,
            group: {
              ...group,
              parent: { id: 1 },
            },
          },
        });
      });

      describe('when confirm is emitted', () => {
        beforeEach(() => {
          findDangerConfirmModal().vm.$emit('confirm', {
            preventDefault: jest.fn(),
          });
        });

        it('emits `confirm` event to parent', () => {
          expect(wrapper.emitted('confirm')).toHaveLength(1);
        });
      });

      describe('when change is emitted', () => {
        beforeEach(() => {
          findDangerConfirmModal().vm.$emit('change', false);
        });

        it('emits `change` event to parent', () => {
          expect(wrapper.emitted('change')).toMatchObject([[false]]);
        });
      });
    });
  });
});
