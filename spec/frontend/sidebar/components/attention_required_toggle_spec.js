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
    factory({ type: 'reviewer', user: { attention_requested: false } });

    expect(findToggle().exists()).toBe(true);
  });

  it.each`
    attentionRequested | icon
    ${true}            | ${'star'}
    ${false}           | ${'star-o'}
  `(
    'renders $icon icon when attention_requested is $attentionRequested',
    ({ attentionRequested, icon }) => {
      factory({ type: 'reviewer', user: { attention_requested: attentionRequested } });

      expect(findToggle().props('icon')).toBe(icon);
    },
  );

  it.each`
    attentionRequested | variant
    ${true}            | ${'warning'}
    ${false}           | ${'default'}
  `(
    'renders button with variant $variant when attention_requested is $attentionRequested',
    ({ attentionRequested, variant }) => {
      factory({ type: 'reviewer', user: { attention_requested: attentionRequested } });

      expect(findToggle().props('variant')).toBe(variant);
    },
  );

  it('emits toggle-attention-requested on click', async () => {
    factory({ type: 'reviewer', user: { attention_requested: true } });

    await findToggle().trigger('click');

    expect(wrapper.emitted('toggle-attention-requested')[0]).toEqual([
      {
        user: { attention_requested: true },
        callback: expect.anything(),
      },
    ]);
  });

  it('sets loading on click', async () => {
    factory({ type: 'reviewer', user: { attention_requested: true } });

    await findToggle().trigger('click');

    expect(findToggle().props('loading')).toBe(true);
  });

  it.each`
    type          | attentionRequested | tooltip
    ${'reviewer'} | ${true}            | ${AttentionRequestedToggle.i18n.removeAttentionRequested}
    ${'reviewer'} | ${false}           | ${AttentionRequestedToggle.i18n.attentionRequestedReviewer}
    ${'assignee'} | ${false}           | ${AttentionRequestedToggle.i18n.attentionRequestedAssignee}
  `(
    'sets tooltip as $tooltip when attention_requested is $attentionRequested and type is $type',
    ({ type, attentionRequested, tooltip }) => {
      factory({ type, user: { attention_requested: attentionRequested } });

      expect(findToggle().attributes('aria-label')).toBe(tooltip);
    },
  );
});
