import { nextTick } from 'vue';
import { GlModal } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import GroupListItemPreventDeleteModal from '~/vue_shared/components/groups_list/group_list_item_prevent_delete_modal.vue';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import { stubComponent } from 'helpers/stub_component';
import { groups } from './mock_data';

describe('GroupListItemPreventDeleteModal', () => {
  let wrapper;

  const [group] = groups;

  const defaultProps = {
    visible: true,
    modalId: '123',
    group,
  };

  const GlModalStub = stubComponent(GlModal);

  const createComponent = ({ props = {}, slots = {} } = {}) => {
    wrapper = mountExtended(GroupListItemPreventDeleteModal, {
      propsData: { ...defaultProps, ...props },
      slots,
      stubs: {
        GlModal: GlModalStub,
      },
    });
  };

  const findGlModal = () => wrapper.findComponent(GlModal);

  beforeEach(async () => {
    createComponent();
    await nextTick();
  });

  it('renders modal with correct props', () => {
    expect(findGlModal().props()).toMatchObject({
      visible: defaultProps.visible,
      modalId: defaultProps.modalId,
      title: "Group can't be be deleted",
      actionCancel: {
        text: 'Cancel',
      },
    });
  });

  it('renders modal body', () => {
    expect(findGlModal().text()).toContain(
      "This group can't be deleted because it is linked to a subscription. To delete this group, link the subscription with a different group.",
    );
    expect(findGlModal().findComponent(HelpPageLink).props()).toMatchObject({
      href: 'subscriptions/gitlab_com/_index',
      anchor: 'link-subscription-to-a-group',
    });
  });

  describe('when change is emitted', () => {
    beforeEach(() => {
      findGlModal().vm.$emit('change', false);
    });

    it('emits `change` event to parent', () => {
      expect(wrapper.emitted('change')).toMatchObject([[false]]);
    });
  });
});
