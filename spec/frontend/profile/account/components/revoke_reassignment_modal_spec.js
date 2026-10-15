import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';

import RevokeReassignmentModal from '~/profile/account/components/revoke_reassignment_modal.vue';
import { mockReassignedSourceUsers } from '../mock_data';

describe('RevokeReassignmentModal', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(RevokeReassignmentModal, {
      propsData: {
        visible: true,
        sourceUser: mockReassignedSourceUsers[0],
        ...props,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
        GlSprintf,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findSourceUserName = () => wrapper.find('strong');

  it('renders the modal with a danger primary action', () => {
    createComponent();

    expect(findModal().props()).toMatchObject({
      visible: true,
      title: 'Revoke contribution reassignment?',
      actionPrimary: {
        text: 'Revoke reassignment',
        attributes: { variant: 'danger' },
      },
    });
  });

  it('emits primary when primary action is clicked', () => {
    createComponent();

    findModal().vm.$emit('primary');

    expect(wrapper.emitted('primary')).toHaveLength(1);
  });

  it('emits hidden when modal is hidden', () => {
    createComponent();

    findModal().vm.$emit('hidden');

    expect(wrapper.emitted('hidden')).toHaveLength(1);
  });

  describe('source user name', () => {
    it('renders the source name when present', () => {
      createComponent();

      expect(findSourceUserName().text()).toBe('Old User 1');
    });

    it('falls back to the source username when the source name is missing', () => {
      createComponent({
        props: {
          sourceUser: { ...mockReassignedSourceUsers[0], sourceName: null },
        },
      });

      expect(findSourceUserName().text()).toBe('old_user_1');
    });

    it('falls back to the source hostname when the source name and username are missing', () => {
      createComponent({
        props: {
          sourceUser: { ...mockReassignedSourceUsers[0], sourceName: null, sourceUsername: null },
        },
      });

      expect(findSourceUserName().text()).toBe('https://gitlab.com');
    });
  });
});
