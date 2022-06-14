import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import AttentionRequestedToggle from '~/sidebar/components/attention_requested_toggle.vue';

let wrapper;

function factory(propsData = {}) {
  wrapper = mount(AttentionRequestedToggle, { propsData });
}

const findToggle = () => wrapper.findComponent(GlButton);

describe('Attention require toggle', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  it('renders button', () => {
    factory({
      type: 'reviewer',
      user: { attention_requested: false, can_update_merge_request: true },
    });

    expect(findToggle().exists()).toBe(true);
  });

  it.each`
    attentionRequested | icon
    ${true}            | ${'attention-solid'}
    ${false}           | ${'attention'}
  `(
    'renders $icon icon when attention_requested is $attentionRequested',
    ({ attentionRequested, icon }) => {
      factory({
        type: 'reviewer',
        user: { attention_requested: attentionRequested, can_update_merge_request: true },
      });

      expect(findToggle().props('icon')).toBe(icon);
    },
  );

  it.each`
    attentionRequested | selected
    ${true}            | ${true}
    ${false}           | ${false}
  `(
    'renders button with as selected when $selected when attention_requested is $attentionRequested',
    ({ attentionRequested, selected }) => {
      factory({
        type: 'reviewer',
        user: { attention_requested: attentionRequested, can_update_merge_request: true },
      });

      expect(findToggle().props('selected')).toBe(selected);
    },
  );

  it('emits toggle-attention-requested on click', async () => {
    factory({
      type: 'reviewer',
      user: { attention_requested: true, can_update_merge_request: true },
    });

    await findToggle().trigger('click');

    expect(wrapper.emitted('toggle-attention-requested')[0]).toEqual([
      {
        user: { attention_requested: true, can_update_merge_request: true },
        callback: expect.anything(),
        direction: 'remove',
      },
    ]);
  });

  it('does not emit toggle-attention-requested on click if can_update_merge_request is false', async () => {
    factory({
      type: 'reviewer',
      user: { attention_requested: true, can_update_merge_request: false },
    });

    await findToggle().trigger('click');

    expect(wrapper.emitted('toggle-attention-requested')).toBe(undefined);
  });

  it('sets loading on click', async () => {
    factory({
      type: 'reviewer',
      user: { attention_requested: true, can_update_merge_request: true },
    });

    await findToggle().trigger('click');

    expect(findToggle().props('loading')).toBe(true);
  });

  it.each`
    type          | attentionRequested | tooltip                                                           | canUpdateMergeRequest
    ${'reviewer'} | ${true}            | ${AttentionRequestedToggle.i18n.removeAttentionRequest}           | ${true}
    ${'reviewer'} | ${false}           | ${AttentionRequestedToggle.i18n.addAttentionRequest}              | ${true}
    ${'assignee'} | ${false}           | ${AttentionRequestedToggle.i18n.addAttentionRequest}              | ${true}
    ${'reviewer'} | ${true}            | ${AttentionRequestedToggle.i18n.attentionRequestedNoPermission}   | ${false}
    ${'reviewer'} | ${false}           | ${AttentionRequestedToggle.i18n.noAttentionRequestedNoPermission} | ${false}
    ${'assignee'} | ${true}            | ${AttentionRequestedToggle.i18n.attentionRequestedNoPermission}   | ${false}
    ${'assignee'} | ${false}           | ${AttentionRequestedToggle.i18n.noAttentionRequestedNoPermission} | ${false}
  `(
    'sets tooltip as $tooltip when attention_requested is $attentionRequested, type is $type and, can_update_merge_request is $canUpdateMergeRequest',
    ({ type, attentionRequested, tooltip, canUpdateMergeRequest }) => {
      factory({
        type,
        user: {
          attention_requested: attentionRequested,
          can_update_merge_request: canUpdateMergeRequest,
        },
      });

      expect(findToggle().attributes('aria-label')).toBe(tooltip);
    },
  );
});
