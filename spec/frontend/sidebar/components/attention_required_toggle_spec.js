import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import AttentionRequiredToggle from '~/sidebar/components/attention_required_toggle.vue';

let wrapper;

function factory(propsData = {}) {
  wrapper = mount(AttentionRequiredToggle, { propsData });
}

const findToggle = () => wrapper.findComponent(GlButton);

describe('Attention require toggle', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  it('renders button', () => {
    factory({ type: 'reviewer', user: { attention_required: false } });

    expect(findToggle().exists()).toBe(true);
  });

  it.each`
    attentionRequired | icon
    ${true}           | ${'star'}
    ${false}          | ${'star-o'}
  `(
    'renders $icon icon when attention_required is $attentionRequired',
    ({ attentionRequired, icon }) => {
      factory({ type: 'reviewer', user: { attention_required: attentionRequired } });

      expect(findToggle().props('icon')).toBe(icon);
    },
  );

  it.each`
    attentionRequired | variant
    ${true}           | ${'warning'}
    ${false}          | ${'default'}
  `(
    'renders button with variant $variant when attention_required is $attentionRequired',
    ({ attentionRequired, variant }) => {
      factory({ type: 'reviewer', user: { attention_required: attentionRequired } });

      expect(findToggle().props('variant')).toBe(variant);
    },
  );

  it('emits toggle-attention-required on click', async () => {
    factory({ type: 'reviewer', user: { attention_required: true } });

    await findToggle().trigger('click');

    expect(wrapper.emitted('toggle-attention-required')[0]).toEqual([
      {
        user: { attention_required: true },
        callback: expect.anything(),
      },
    ]);
  });

  it('sets loading on click', async () => {
    factory({ type: 'reviewer', user: { attention_required: true } });

    await findToggle().trigger('click');

    expect(findToggle().props('loading')).toBe(true);
  });

  it.each`
    type          | attentionRequired | tooltip
    ${'reviewer'} | ${true}           | ${AttentionRequiredToggle.i18n.removeAttentionRequired}
    ${'reviewer'} | ${false}          | ${AttentionRequiredToggle.i18n.attentionRequiredReviewer}
    ${'assignee'} | ${false}          | ${AttentionRequiredToggle.i18n.attentionRequiredAssignee}
  `(
    'sets tooltip as $tooltip when attention_required is $attentionRequired and type is $type',
    ({ type, attentionRequired, tooltip }) => {
      factory({ type, user: { attention_required: attentionRequired } });

      expect(findToggle().attributes('aria-label')).toBe(tooltip);
    },
  );
});
