import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupListItemDeleteModal from '~/vue_shared/components/groups_list/group_list_item_delete_modal.vue';
import DangerConfirmModal from '~/vue_shared/components/confirm_danger/confirm_danger_modal.vue';

describe('GroupListItemDeleteModalCE', () => {
  let wrapper;

  const defaultProps = {
    modalId: '123',
    phrase: 'mock phrase',
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(GroupListItemDeleteModal, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findDangerConfirmModal = () => wrapper.findComponent(DangerConfirmModal);

  describe('when visible is false', () => {
    beforeEach(() => {
      createComponent({ props: { visible: false } });
    });

    it('does not render modal', () => {
      expect(findDangerConfirmModal().exists()).toBe(false);
    });
  });

  describe('when visible is true', () => {
    beforeEach(() => {
      createComponent({ props: { visible: true } });
    });

    it('does render modal', () => {
      expect(findDangerConfirmModal().exists()).toBe(true);
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
