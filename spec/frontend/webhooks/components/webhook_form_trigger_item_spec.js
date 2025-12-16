import { nextTick } from 'vue';
import { GlFormCheckbox, GlLink } from '@gitlab/ui';
import WebhookFormTriggerItem from '~/webhooks/components/webhook_form_trigger_item.vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('WebhookFormTriggerItem', () => {
  let wrapper;

  const label = 'Enable me';
  const helpText = 'Helpful text';
  const helpLinkPath = 'docs/help';
  const helpLinkText = 'Learn more';

  const createComponent = (mountFn = shallowMountExtended, { props } = {}) => {
    wrapper = mountFn(WebhookFormTriggerItem, {
      propsData: {
        triggerName: 'custom-trigger',
        inputName: 'custom_trigger',
        label,
        ...props,
      },
    });
  };

  const findTriggerCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findHelpText = () => wrapper.find('.help-text');
  const findHelpLink = () => wrapper.findComponent(GlLink);

  describe('by default', () => {
    beforeEach(() => {
      createComponent();
    });
    it('displays the correct trigger text', () => {
      expect(wrapper.text()).toBe(label);
    });

    it('excludes help subtext if none is passed', () => {
      expect(findHelpText().exists()).toBe(false);
    });
  });

  it('includes help subtext when passed', () => {
    createComponent(mountExtended, { props: { helpText } });

    expect(findHelpText().text()).toBe(helpText);
  });

  describe('help link', () => {
    it('includes link to docs when both link text and link path are passed', () => {
      createComponent(mountExtended, { props: { helpText, helpLinkText, helpLinkPath } });

      const link = findHelpLink();
      expect(link.text()).toBe(helpLinkText);
      expect(link.attributes('href')).toContain(helpLinkPath);
    });

    it('does not render link when missing link text', () => {
      createComponent(mountExtended, { props: { helpText, helpLinkPath } });

      expect(findHelpLink().exists()).toBe(false);
    });

    it('does not render link when missing link path', () => {
      createComponent(mountExtended, { props: { helpText, helpLinkText } });

      expect(findHelpLink().exists()).toBe(false);
    });
  });

  it('correctly sends value when checkbox is checked and unchecked', async () => {
    createComponent();
    const checkbox = findTriggerCheckbox();

    await checkbox.vm.$emit('input', true);
    await nextTick();

    await checkbox.vm.$emit('input', false);
    expect(wrapper.emitted('input')).toEqual([[true], [false]]);
  });

  it('hidden input correctly changes when the checkbox is unchecked', async () => {
    createComponent(mountExtended, { props: { value: true } });
    const hiddenInput = wrapper.find('input[type="hidden"]');

    expect(hiddenInput.attributes('value')).toBe('1');
    wrapper.setProps({ value: false });
    await nextTick();

    expect(hiddenInput.attributes('value')).toBe('0');
  });
});
