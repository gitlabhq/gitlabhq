import { nextTick } from 'vue';
import { GlButton, GlLink, GlPopover } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import EditorModeSwitcher from '~/vue_shared/components/markdown/editor_mode_switcher.vue';
import { counter } from '~/vue_shared/components/markdown/utils';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import { stubComponent } from 'helpers/stub_component';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';

jest.mock('~/vue_shared/components/markdown/utils', () => ({
  counter: jest.fn().mockReturnValue(0),
}));

describe('vue_shared/component/markdown/editor_mode_switcher', () => {
  let wrapper;
  useLocalStorageSpy();

  const createComponent = ({
    value,
    userCalloutDismisserSlotProps = { dismiss: jest.fn() },
  } = {}) => {
    wrapper = mount(EditorModeSwitcher, {
      propsData: {
        value,
      },
      stubs: {
        UserCalloutDismisser: stubComponent(UserCalloutDismisser, {
          render() {
            return this.$scopedSlots.default(userCalloutDismisserSlotProps);
          },
        }),
      },
    });
  };

  const findSwitcherButton = () => wrapper.findComponent(GlButton);
  const findUserCalloutDismisser = () => wrapper.findComponent(UserCalloutDismisser);
  const findCalloutPopover = () => wrapper.findComponent(GlPopover);

  describe.each`
    value         | buttonText
    ${'richText'} | ${'Switch to plain text editing'}
    ${'markdown'} | ${'Switch to rich text editing'}
  `('when $value', ({ value, buttonText }) => {
    beforeEach(() => {
      createComponent({ value });
    });

    it('shows correct button label', () => {
      expect(findSwitcherButton().text()).toEqual(buttonText);
    });

    it('emits event on click', async () => {
      await nextTick();
      findSwitcherButton().vm.$emit('click');

      expect(wrapper.emitted().switch).toEqual([[false]]);
    });
  });

  describe('rich text editor callout', () => {
    let dismiss;

    beforeEach(() => {
      dismiss = jest.fn();
      createComponent({ value: 'markdown', userCalloutDismisserSlotProps: { dismiss } });
    });

    it('does not skip the user_callout_dismisser query', () => {
      expect(findUserCalloutDismisser().props()).toMatchObject({
        skipQuery: false,
        featureName: 'rich_text_editor',
      });
    });

    it('mounts new rich text editor popover', () => {
      expect(findCalloutPopover().props()).toMatchObject({
        showCloseButton: '',
        triggers: 'manual',
        target: 'switch-to-rich-text-editor',
      });
    });

    it('dismisses the callout and emits "switch" event when popover close button is clicked', async () => {
      await findCalloutPopover().findComponent(GlLink).vm.$emit('click');

      expect(wrapper.emitted().switch).toEqual([[true]]);
      expect(dismiss).toHaveBeenCalled();
    });

    it('dismisses the callout when action button is clicked', () => {
      findSwitcherButton().vm.$emit('click');

      expect(dismiss).toHaveBeenCalled();
    });

    it('does not show the callout if rich text is already enabled', async () => {
      await wrapper.setProps({ value: 'richText' });

      expect(findCalloutPopover().props()).toMatchObject({
        show: false,
      });
    });

    it('does not show the callout if already displayed once on the page', () => {
      counter.mockReturnValue(1);

      createComponent({ value: 'markdown' });

      expect(findCalloutPopover().props()).toMatchObject({
        show: false,
      });
    });
  });
});
