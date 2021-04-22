import { GlModal } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ConfirmModal from '~/deploy_keys/components/confirm_modal.vue';

describe('~/deploy_keys/components/confirm_modal.vue', () => {
  let wrapper;
  let modal;

  beforeEach(() => {
    wrapper = mount(ConfirmModal, { propsData: { modalId: 'test', visible: true } });
    modal = extendedWrapper(wrapper.findComponent(GlModal));
  });

  it('emits a remove event if the primary button is clicked', () => {
    modal.findByText('Remove deploy key').trigger('click');
    expect(wrapper.emitted('remove')).toEqual([[]]);
  });

  it('emits a cancel event if the secondary button is clicked', () => {
    modal.findByText('Cancel').trigger('click');
    expect(wrapper.emitted('cancel')).toEqual([[]]);
  });

  it('displays the warning about removing the deploy key', () => {
    expect(modal.text()).toContain('Are you sure you want to remove this deploy key?');
  });
});
